import { Server } from "./infra/api/server";
import { Db } from "./infra/storage/db";
import { Entity1Router } from "./api/routers/entity-1-router";

const PORT = 8080;

class App {
  public static run(): void {
    Db.run("build/src/storage/entities/*.js")
      .then(() => {
        return Server.run(PORT, [new  Entity1Router()]);
      })
      .catch((err) => {
        console.error(err);
      });
  }
}
App.run();
