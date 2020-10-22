import { Server } from "./infra/api/server";
import { Db } from "./infra/storage/db";
import { Entity2Router } from "./api/routers/entity-2-router";

const PORT = 8081;

class App {
  public static run(): void {
    Db.run("build/src/storage/entities/*.js")
      .then(() => {
        return Server.run(PORT, [new  Entity2Router()]);
      })
      .catch((err) => {
        console.error(err);
      });
  }
}
App.run();
