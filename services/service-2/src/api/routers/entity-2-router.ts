import { Express, Router, Request, Response, IRouter } from "../../infra/api/server";
import { Entity2Controller } from "../../bl/controllers/entity-2-controller";
import { Entity2 } from "../../storage/entities/entity-2";

export class Entity2Router implements IRouter {

  public run(app: Express, router: Router): void {
    var controller: Entity2Controller = new Entity2Controller();

    // Create a new entity2
    router.post("/", async (req: Request, res: Response) => {
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      const entity2 = new Entity2();
      entity2.payload = req.body.payload;
      var result = await controller.create(entity2);     
      res.status(201).json(result);
    });

    // Retrieve all entity2
    router.get("/", async (req: Request, res: Response) => {
      var result = await controller.getAll();
      res.json(result);
    });

    // Retrieve a single entity2 with id
    router.get("/:id", async (req: Request, res: Response) => {
      let entity2Id: number = parseInt(req.params.id);
      if (isNaN(entity2Id)) {
        res.status(400).send("URL token for entity2 Id is not a number");
        return;
      }
      var result = await controller.get(entity2Id);
      if (!result) {
        res.status(404).send("Entity2 with Id '" + entity2Id + "' not found");
      }
      res.json(result);
    });

    // Update a single entity2 with id
    router.put("/:id", async (req: Request, res: Response) => {
      let entity2Id: number = parseInt(req.params.id);
      if (isNaN(entity2Id)) {
        res.status(400).send("URL token for entity2 Id is not a number");
        return;
      }
      if (!req.body.payload) {
        res.status(400).send("Body property 'payload' is missing");
        return;
      }
      let entity2 = new Entity2();
      entity2.payload = req.body.payload;
      var result = await controller.update(entity2Id, entity2);
      if (!result) {
        res.status(404).send("Entity2 with Id '" + entity2Id + "' not found");
      }
      res.json(result);
    });

    // Delete a single entity2 with id
    router.delete("/:id", async (req: Request, res: Response) => {
      let entity2Id: number = parseInt(req.params.id);
      if (isNaN(entity2Id)) {
        res.status(400).send("URL token for entity2 Id is not a number");
        return;
      }
      var result = await controller.delete(entity2Id);
      if (!result) {
        res.status(404).send("Entity2 with Id '" + entity2Id + "' not found");
      }
      res.json(result);
    });

    app.use("/api/entity2s", router);
  }
}
