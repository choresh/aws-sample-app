import { Entity1 } from "../src/storage/entities/entity-1";
import superagent from "superagent";
var expect = require("chai").expect;

const CONNECTION_RETRY_COUNT: number = 10;
const CONNECTION_RETRY_TIMEOUT_MS: number = 10000;

// Env variables 'SERVICE_HOST' and 'SERVICE_PORT' defined in 'docker-compose.test.yml', the default
// values 'localhost' and '8081' will be selected if run performed without the 'docker-compose.test.yml'
// (e.g. while developer runs the service and test locally, out of docker machine).
const serviceHost: string = process.env.SERVICE_HOST || "localhost";
const servicePort: string = process.env.SERVICE_PORT || "8080";
const serviceUri = "http://" + serviceHost + ":" + servicePort + "/api/entity1s"
 
describe("REST API Tests", () => {
  
  // Clear the DB - before each run of this tests collection
  before(async () => {
   
    console.log("Configured service uri:", serviceUri);

    for (var i = 1; ; i++) {
      try {
        console.log("Connect to app's REST API started, attempt " + i + "/" + CONNECTION_RETRY_COUNT);
        const getRes: superagent.Response = await superagent.get(serviceUri);
        console.log("Connect to app's REST API ended");
        let getResult: Entity1[] = <Entity1[]><any>getRes.body;
        let deletePromises = getResult.map((currEntity1: Entity1) => {
            return superagent.delete(serviceUri + "/" + currEntity1.id);
        });
        await Promise.all(deletePromises);
        break;
      } catch (err) {
        if (i === CONNECTION_RETRY_COUNT) {
          console.log("Connect to app's REST API failed, error:", err);
          throw err;
        }
        await new Promise<void>((resolve, reject) => {
          setTimeout(() => {
            resolve();
          }, CONNECTION_RETRY_TIMEOUT_MS);
        }); 
      }
    }
  });

  let payloads: string[] = ["AAAAA", "BBBBB", "CCCCC", "DDDDD"];

  it("Create entity1s", async () => {
    for (var i = 0; i < payloads.length; i++) {
        const currRes: superagent.Response = await superagent.post(serviceUri)
                                                  .send({payload: payloads[i]});
        let currResult: Entity1 = <Entity1><any>currRes.body;
        expect(currResult).to.include({payload: payloads[i]});
    }   
  });

  it("Retrieve all entity1s", async () => {
    const res: superagent.Response = await superagent.get(serviceUri);
    let result: Entity1[] = <Entity1[]><any>res.body;  
    expect(result.length).to.equal(payloads.length);  
    let resultPayloads = result.map((currEntity1: Entity1) => {
        return currEntity1.payload;
    }); 
    console.log("Retrieve all entity1s result payloads:", resultPayloads);
    expect(resultPayloads).to.have.all.members(payloads); 
  });
});