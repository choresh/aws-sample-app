import express, { Express } from "express";
import Router from "express-promise-router";
import { json } from "body-parser";
import console from "console";
export { Express, Router, Request, Response } from "express";

export interface IRouter {
  run(app: Express, router: any): void
}

export class Server {
  private static _app: Express = express();
  private static _router = Router();

  public static async run(port: number, routers: IRouter[]): Promise<void> {

    // Parse requests of content-type - application/json
    this._app.use(json());
  
    // Enable easy conversion from 'Promise' to express midleware
    this._app.use(this._router);

    // Attach routers (currently - only one)
    routers.forEach((currRouter: IRouter) => {
      currRouter.run(this._app, this._router); 
    });
      
    // Start listen for requests
    return new Promise((resolve, reject) => {
      this._app.listen(port, () => {
        console.log(`Server is running on port ${port}.`);
        resolve();
      });
    });
  }
}
