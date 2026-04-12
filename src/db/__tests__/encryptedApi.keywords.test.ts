import { describe, expect, it, vi } from "vitest";

vi.mock("@/db/encryptedDatabase", () => {
  return {
    getEncryptedArticles: vi.fn(),
    saveEncryptedArticle: vi.fn(),
    deleteEncryptedArticle: vi.fn(),
    getEncryptedArticleById: vi.fn(),
    getEncryptedSites: vi.fn(),
    saveEncryptedSite: vi.fn(),
    deleteEncryptedSite: vi.fn(),
    getEncryptedAISettings: vi.fn(),
    saveEncryptedAISettings: vi.fn(),
    getEncryptedTemplates: vi.fn(),
    saveEncryptedTemplate: vi.fn(),
    deleteEncryptedTemplate: vi.fn(),
    getEncryptedKeywords: vi.fn(),
    saveEncryptedKeyword: vi.fn(),
    deleteEncryptedKeyword: vi.fn(),
    getEncryptedTopics: vi.fn(),
    saveEncryptedTopic: vi.fn(),
    deleteEncryptedTopic: vi.fn(),
    getEncryptedArticleVersions: vi.fn(),
    saveEncryptedArticleVersion: vi.fn(),
    deleteEncryptedArticleVersion: vi.fn(),
    setEncryptedKeywords: vi.fn(),
    setEncryptedTopics: vi.fn(),
    setEncryptedTemplates: vi.fn(),
    exportUserData: vi.fn(),
    importUserData: vi.fn(),
    clearUserData: vi.fn(),
    hasEncryptionKey: vi.fn(() => true),
  };
});

import { getEncryptedKeywords, setEncryptedKeywords } from "@/db/encryptedDatabase";
import { createKeywordsBatch } from "@/db/encryptedApi";

describe("encryptedApi.createKeywordsBatch", () => {
  it("批量创建时跳过重复关键词并追加写入", async () => {
    vi.mocked(getEncryptedKeywords).mockResolvedValue([
      {
        id: "k1",
        user_id: "u1",
        keyword: "foo",
        group_name: "G",
        use_count: 0,
        created_at: "2020-01-01T00:00:00.000Z",
      },
    ]);

    const result = await createKeywordsBatch("u1", ["foo", "bar", "  ", "baz"], "G");

    expect(result).toEqual({ created: 2, skipped: 1 });
    expect(setEncryptedKeywords).toHaveBeenCalledTimes(1);
    const [, next] = vi.mocked(setEncryptedKeywords).mock.calls[0];
    expect(next.map((k) => k.keyword)).toEqual(["foo", "bar", "baz"]);
  });
});

