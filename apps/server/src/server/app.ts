import cors from "@elysiajs/cors";
import swagger from "@elysiajs/swagger";
import { apiEnv } from "@kombination/env";
import Elysia from "elysia";

import { loadControllers } from "@utils/controllers-loader";

export class App {
  private _app: Elysia;

  constructor() {
    this._app = new Elysia();

    this.setupPlugins(this._app);
  }

  private setupPlugins(app: Elysia) {
    app.use(cors());
    app.use(
      swagger({
        path: "/swagger",
        documentation: {
          info: { title: "Kombination API", version: "0.0.1" },
        },
      }),
    );
  }

  public async initialize() {
    await loadControllers(this._app);
  }

  public async start() {
    await this.initialize();
    console.info("enviroment:", apiEnv.NODE_ENV);
    const PORT = apiEnv.PORT || 3001;

    this._app.listen(Number(PORT));
    console.log(
      `🦊 Elysia is running at ${this._app.server?.hostname}:${this._app.server?.port}`,
    );
  }
}
