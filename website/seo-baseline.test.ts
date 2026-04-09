import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { expect, test } from "bun:test";

const public_dir = join(import.meta.dir, "public");
const robots_path = join(public_dir, "robots.txt");
const sitemap_path = join(public_dir, "sitemap.xml");

function read_if_present(file_path: string): string {
  return existsSync(file_path) ? readFileSync(file_path, "utf8") : "";
}

test("robots.txt publishes the minimum owned crawl baseline", () => {
  expect(existsSync(robots_path)).toBeTrue();

  const robots = read_if_present(robots_path);

  expect(robots).toContain("User-agent: *");
  expect(robots).toContain("Allow: /");
  expect(robots).toContain("Sitemap: /sitemap.xml");
});

test("sitemap.xml publishes the minimum owned routes baseline", () => {
  expect(existsSync(sitemap_path)).toBeTrue();

  const sitemap = read_if_present(sitemap_path);

  expect(sitemap).toContain("<urlset");
  expect(sitemap).toContain("<loc>/</loc>");
  expect(sitemap).toContain("<loc>/docs</loc>");
  expect(sitemap).toContain("<loc>/install</loc>");
  expect(sitemap).not.toContain("/samples/");
  expect(sitemap).not.toContain("/gallery/");
});
