import { Server } from "../../infra/src/api/server";
import { Db } from "../../infra/src/storage/db";
import { Entity1Router } from "./api/routers/entity-1-router";

const PORT = 8080;

class App {
  public static run(): void {
    Db.run("build/service-1/src/storage/entities/*.js")
      .then(() => {
        return Server.run(PORT, [new  Entity1Router()]);
      })
      .catch((err) => {
        console.error(err);
      });
  }
}
App.run();
