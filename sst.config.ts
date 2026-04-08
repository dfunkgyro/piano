import { SSTConfig } from "sst";

export default {
  config() {
    return {
      name: "grandpiano",
      region: "us-east-1",
    };
  },
  async stacks(app) {
    const mod = await import("./stacks/AppStack");
    app.stack(mod.AppStack);
  },
} satisfies SSTConfig;
