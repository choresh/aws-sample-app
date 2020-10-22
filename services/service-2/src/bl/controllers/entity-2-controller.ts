import { Entity2 } from "../../storage/entities/entity-2";
import { Db, Repository } from "../../infra/storage/db";

export class Entity2Controller {
  private _repository: Repository<Entity2>;
 
  public constructor() {
    this._repository = Db.getConnection().getRepository(Entity2);
  }

  public async create(entity2: Entity2): Promise<Entity2> {
    return await this._repository.save(entity2);
  }

  public async update(id: number, entity2: Entity2): Promise<Entity2> {    
    let entityToUpdate: Entity2 = await this._repository.findOne(id);
    if (!entityToUpdate) {
      return;
    }
    entityToUpdate.payload = entity2.payload;
    return await this._repository.save(entityToUpdate);
  }

  public async getAll(): Promise<Entity2[]> {
    return await this._repository.find();             
  }

  public async get(id: number): Promise<Entity2> {
    return await this._repository.findOne(id);           
  }  

  public async delete(id: number): Promise<Entity2> {
    let entityToRemove: Entity2 = await this._repository.findOne(id); 
    if (!entityToRemove) {
      return;
    }
    return await this._repository.remove(entityToRemove);
  }
}
