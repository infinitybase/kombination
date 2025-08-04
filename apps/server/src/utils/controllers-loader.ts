import type Elysia from "elysia";
import { existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// Get current file's path for resolving directories
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Loads and registers all controllers from the controllers directory
 * @param app The Elysia application instance
 * @returns Promise that resolves when all controllers are loaded
 */
export async function loadControllers(app: Elysia): Promise<void> {
  let controllersPath = "";

  // Try to determine the correct path for controllers
  // First check development path (relative to source file)
  const devPath = join(__dirname, "../http/controllers");
  // Then check production path (after bundle)
  const prodPath = join(process.cwd(), "src/http/controllers");

  if (existsSync(devPath)) {
    controllersPath = devPath;
  } else if (existsSync(prodPath)) {
    controllersPath = prodPath;
  } else {
    throw new Error(
      "Controllers directory not found. Please check your project structure.",
    );
  }

  try {
    const files = readdirSync(controllersPath);

    for (const file of files) {
      // Skip index file and non-JS/TS files
      if (
        file === "index.ts" ||
        file === "index.js" ||
        (!file.endsWith(".ts") && !file.endsWith(".js"))
      ) {
        continue;
      }

      try {
        // For ESM compatibility, form the proper import URL
        const controllerPath = `file://${join(controllersPath, file).replace(/\\/g, "/")}`;
        const controllerModule = await import(controllerPath);
        const ControllerClass = controllerModule.default;

        if (typeof ControllerClass === "function") {
          const controller = new ControllerClass();
          if (typeof controller.routes === "function") {
            controller.routes(app);
            console.log(`Registered routes from controller: ${file}`);
          } else {
            console.warn(
              `Controller in ${file} does not have a routes method.`,
            );
          }
        } else {
          console.warn(
            `File ${file} does not export a valid controller class.`,
          );
        }
      } catch (error) {
        console.error(`Error loading controller ${file}:`, error);
      }
    }
  } catch (error) {
    console.error("Error scanning controllers directory:", error);
    throw error;
  }
}
