// RUN: utilities/loginShare.js | clip.exe

const { exec } = require("child_process");
let chalk;

// Import chalk
import("chalk").then((module) => {
  chalk = module.default;
});

// función para ejecutar exec y capturar la salida como promesa
function loginCommand(comando) {
  return new Promise((resolve, reject) => {
    exec(comando, (error, stdout, stderr) => {
      if (error) {
        reject(`Error: ${error}`);
      } else {
        resolve(stdout);
      }
    });
  });
}

async function doLogins() {
  try {
    const login1 = "sfdx force:org:open -u business--replica --urlonly";
    const login2 = "sfdx force:org:open -u business--prod --urlonly";
    // Lanzamos ambas llamadas en paralelo y esperamos a que terminen
    const [login1Front, login2Front] = await Promise.all([
      loginCommand(login1),
      loginCommand(login2),
    ]);

    const concatLogins = `${chalk.hex("#ffb02e")("🟨 RÉPLICA")} ${login1Front}
    ${chalk.red("🟥 PRODUCCIÓN")} ${login2Front}`;
    console.log(concatLogins);
  } catch (error) {
    console.error("Ocurrión un error: ", error);
  }
}

doLogins();
