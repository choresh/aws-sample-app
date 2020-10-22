import {Entity, Column, PrimaryGeneratedColumn} from "../../infra/storage/db";

@Entity({ name: "Entity2s" })
export class Entity2 {

  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  payload: string;
}
