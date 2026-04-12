import { describe, expect, it } from "vitest";

import * as api from "@/db/api";
import { db } from "@/db/database";

describe("stage07 facade convergence", () => {
  it("api exports ai settings and version helpers from the unified facade", () => {
    expect(typeof api.getAllAISettings).toBe("function");
    expect(typeof api.getEffectiveAISettings).toBe("function");
    expect(typeof api.getImageSettings).toBe("function");
    expect(typeof api.getArticleVersions).toBe("function");
    expect(typeof api.createArticleVersion).toBe("function");
    expect(typeof api.deleteAllArticleVersions).toBe("function");
  });

  it("database facade only exposes the user table", () => {
    expect("users" in db).toBe(true);
    expect("articles" in db).toBe(false);
    expect("wordpress_sites" in db).toBe(false);
    expect("ai_settings" in db).toBe(false);
  });
});
