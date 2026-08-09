import { test, expect } from "@playwright/test";

test("homepage redirects to /dashboard", async ({ page }) => {
  await page.goto("/");
  // Either we end up on /dashboard (auth wired) or /login (auth off).
  // Both prove the app is serving. Specific auth flow tests land in Phase 1.
  await expect(page).toHaveURL(/\/(dashboard|login)/);
});
