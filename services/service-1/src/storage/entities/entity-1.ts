import {Entity, Column, PrimaryGeneratedColumn} from "../../infra/storage/db";

@Entity({ name: "Entity1s" })
export class Entity1 {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  payload: string;
}
