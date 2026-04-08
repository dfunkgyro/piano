import { StackContext, Api, Table, Bucket, Cognito, Cron } from "sst/constructs";
import * as iam from "aws-cdk-lib/aws-iam";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as sns from "aws-cdk-lib/aws-sns";
import * as subs from "aws-cdk-lib/aws-sns-subscriptions";

export function AppStack({ stack }: StackContext) {
  let allowedOrigins = (process.env.APP_ORIGINS ?? "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);
  if (allowedOrigins.length === 0) {
    allowedOrigins = [
      "https://piano.thegyromusic.com",
      "https://thegyromusic.com",
      "http://localhost:3000",
      "http://localhost:5173",
    ];
  }

  const bedrockModelId =
    process.env.BEDROCK_MODEL_ID || "anthropic.claude-3-5-sonnet-20240620-v1:0";
  const bedrockModelArn = `arn:aws:bedrock:${stack.region}::foundation-model/${bedrockModelId}`;
  const hostedZoneId =
    process.env.ROUTE53_HOSTED_ZONE_ID || "Z103081827M67QYTDSL5L";
  const hostedZoneArn = `arn:aws:route53:::hostedzone/${hostedZoneId}`;

  const auth = new Cognito(stack, "Auth", {
    login: ["email"],
    // Optional: enable Google/Apple federation when client IDs are provided.
    // TODO: Set GOOGLE_CLIENT_ID and APPLE_SERVICES_ID in the deploy env.
    identityPoolFederation:
      process.env.GOOGLE_CLIENT_ID || process.env.APPLE_SERVICES_ID
        ? {
            google: process.env.GOOGLE_CLIENT_ID
              ? { clientId: process.env.GOOGLE_CLIENT_ID }
              : undefined,
            apple: process.env.APPLE_SERVICES_ID
              ? { servicesId: process.env.APPLE_SERVICES_ID }
              : undefined,
          }
        : undefined,
  });

  const sessions = new Table(stack, "Sessions", {
    fields: {
      pk: "string",
      sk: "string",
    },
    primaryIndex: { partitionKey: "pk", sortKey: "sk" },
  });

  const notes = new Table(stack, "Notes", {
    fields: {
      pk: "string",
      sk: "string",
    },
    primaryIndex: { partitionKey: "pk", sortKey: "sk" },
  });

  const songProgress = new Table(stack, "SongProgress", {
    fields: {
      pk: "string",
      sk: "string",
    },
    primaryIndex: { partitionKey: "pk", sortKey: "sk" },
  });

  const profiles = new Table(stack, "Profiles", {
    fields: {
      pk: "string",
      sk: "string",
    },
    primaryIndex: { partitionKey: "pk", sortKey: "sk" },
  });

  const errors = new Table(stack, "Errors", {
    fields: {
      pk: "string",
      sk: "string",
    },
    primaryIndex: { partitionKey: "pk", sortKey: "sk" },
  });

  const errorTopic = new sns.Topic(stack, "ErrorTopic", {
    displayName: "GrandPiano Crash Reports",
  });
  errorTopic.addSubscription(
    new subs.EmailSubscription("gyrotechpro@gmail.com")
  );

  const gyroUser = iam.User.fromUserName(stack, "GyroUser", "gyro");
  const gyroRoute53Policy = new iam.Policy(stack, "GyroRoute53Read", {
    statements: [
      new iam.PolicyStatement({
        actions: ["route53:ListHostedZones"],
        resources: ["*"],
      }),
      new iam.PolicyStatement({
        actions: ["route53:GetHostedZone", "route53:ListResourceRecordSets"],
        resources: [hostedZoneArn],
      }),
    ],
  });
  gyroUser.attachInlinePolicy(gyroRoute53Policy);

  const assets = new Bucket(stack, "Assets", {
    cors: allowedOrigins.length
      ? [
          {
            allowedHeaders: ["*"],
            allowedMethods: ["GET", "PUT", "POST", "HEAD"],
            allowedOrigins,
          },
        ]
      : undefined,
  });

  const webAppBucket = new Bucket(stack, "WebAppBucket", {
    name: "piano.thegyromusic.com",
    cdk: {
      bucket: {
        publicReadAccess: true,
        blockPublicAccess: new s3.BlockPublicAccess({
          blockPublicAcls: false,
          ignorePublicAcls: false,
          blockPublicPolicy: false,
          restrictPublicBuckets: false,
        }),
        websiteIndexDocument: "index.html",
        websiteErrorDocument: "index.html",
      },
    },
  });

  const api = new Api(stack, "Api", {
    cors: {
      allowOrigins: allowedOrigins,
      allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      allowHeaders: ["content-type", "authorization", "x-device-id"],
    },
    authorizers: {
      UserPool: {
        type: "user_pool",
        userPool: {
          id: auth.userPoolId,
          clientIds: [auth.userPoolClientId],
          region: stack.region,
        },
      },
    },
    defaults: {
      function: {
        runtime: "nodejs18.x",
        permissions: [
          new iam.PolicyStatement({
            actions: ["bedrock:InvokeModel"],
            resources: [bedrockModelArn],
          }),
          new iam.PolicyStatement({
            actions: ["sns:Publish"],
            resources: [errorTopic.topicArn],
          }),
        ],
        environment: {
          TABLE_SESSIONS: sessions.tableName,
          TABLE_NOTES: notes.tableName,
          TABLE_SONG_PROGRESS: songProgress.tableName,
          TABLE_PROFILES: profiles.tableName,
          TABLE_ERRORS: errors.tableName,
          ERROR_TOPIC_ARN: errorTopic.topicArn,
          BEDROCK_REGION: stack.region,
          BEDROCK_MODEL_ID: bedrockModelId,
          ALLOW_GUEST_AI: process.env.ALLOW_GUEST_AI ?? "true",
          ALLOWED_ORIGINS: allowedOrigins.join(","),
          ALLOW_DEVICE_ID: process.env.ALLOW_DEVICE_ID ?? "true",
          ALLOW_GUEST_API: process.env.ALLOW_GUEST_API ?? "true",
          ALLOW_SYSTEM_PROMPTS: process.env.ALLOW_SYSTEM_PROMPTS ?? "false",
        },
      },
      authorizer: "UserPool",
      // Basic throttling to reduce abuse risk before auth is enabled.
      throttle: {
        rate: 20,
        burst: 50,
      },
    },
    routes: {
      "POST /sessions/start": "packages/functions/src/sessions/start.handler",
      "POST /sessions/{id}/end": "packages/functions/src/sessions/end.handler",
      "POST /sessions/{id}/notes": "packages/functions/src/sessions/trackNote.handler",
      "POST /sessions/{id}/insights": "packages/functions/src/insights/generate.handler",
      "GET /sessions/{id}/insights": "packages/functions/src/insights/get.handler",
      "GET /sessions/recent": "packages/functions/src/sessions/recent.handler",
      "GET /stats": "packages/functions/src/stats/get.handler",
      "GET /analytics": "packages/functions/src/analytics/get.handler",
      "GET /songs/{id}/progress": "packages/functions/src/songs/getProgress.handler",
      "PUT /songs/{id}/progress": "packages/functions/src/songs/saveProgress.handler",
      "GET /profile": "packages/functions/src/profile/get.handler",
      "GET /errors": "packages/functions/src/errors/list.handler",
      "POST /errors": "packages/functions/src/errors/report.handler",
      "POST /ai/chat": "packages/functions/src/ai/chat.handler",
      "POST /guest/sessions/start": {
        function: "packages/functions/src/sessions/start.handler",
        authorizer: "none",
      },
      "POST /guest/sessions/{id}/end": {
        function: "packages/functions/src/sessions/end.handler",
        authorizer: "none",
      },
      "POST /guest/sessions/{id}/notes": {
        function: "packages/functions/src/sessions/trackNote.handler",
        authorizer: "none",
      },
      "POST /guest/sessions/{id}/insights": {
        function: "packages/functions/src/insights/generate.handler",
        authorizer: "none",
      },
      "GET /guest/sessions/{id}/insights": {
        function: "packages/functions/src/insights/get.handler",
        authorizer: "none",
      },
      "GET /guest/sessions/recent": {
        function: "packages/functions/src/sessions/recent.handler",
        authorizer: "none",
      },
      "GET /guest/stats": {
        function: "packages/functions/src/stats/get.handler",
        authorizer: "none",
      },
      "GET /guest/analytics": {
        function: "packages/functions/src/analytics/get.handler",
        authorizer: "none",
      },
      "GET /guest/songs/{id}/progress": {
        function: "packages/functions/src/songs/getProgress.handler",
        authorizer: "none",
      },
      "PUT /guest/songs/{id}/progress": {
        function: "packages/functions/src/songs/saveProgress.handler",
        authorizer: "none",
      },
      "GET /guest/profile": {
        function: "packages/functions/src/profile/get.handler",
        authorizer: "none",
      },
      "GET /guest/errors": {
        function: "packages/functions/src/errors/list.handler",
        authorizer: "none",
      },
      "POST /guest/errors": {
        function: "packages/functions/src/errors/report.handler",
        authorizer: "none",
      },
      "POST /guest/ai/chat": {
        function: "packages/functions/src/ai/chat.handler",
        authorizer: "none",
      },
    },
  });

  api.bind([sessions, notes, songProgress, profiles, errors]);

  if (process.env.ENABLE_ANALYTICS_CRON === "true") {
    new Cron(stack, "AnalyticsCron", {
      schedule: "rate(1 day)",
      job: "packages/functions/src/analytics/aggregate.handler",
      environment: {
        TABLE_SESSIONS: sessions.tableName,
        TABLE_NOTES: notes.tableName,
      },
    });
  }

  stack.addOutputs({
    ApiUrl: api.url,
    UserPoolId: auth.userPoolId,
    UserPoolClientId: auth.userPoolClientId,
    IdentityPoolId: auth.identityPoolId,
    AssetsBucket: assets.bucketName,
    ErrorsTable: errors.tableName,
    WebAppBucket: webAppBucket.bucketName,
    Region: stack.region,
  });
}
