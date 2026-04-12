import { describe, expect, it, vi } from "vitest";

vi.mock("@/utils/encryptedStorage", () => {
  return {
    saveEncryptedData: vi.fn(),
    loadEncryptedData: vi.fn(),
    removeEncryptedData: vi.fn(),
    hasEncryptedData: vi.fn(),
    exportEncryptedData: vi.fn(),
    importEncryptedData: vi.fn(),
    clearAllUserData: vi.fn(),
    isEncryptionEnabled: vi.fn(),
    setEncryptionKey: vi.fn(),
    hasEncryptionKey: vi.fn(() => true),
  };
});

import { loadEncryptedData, saveEncryptedData } from "@/utils/encryptedStorage";
import { getEncryptedAISettingsList } from "@/db/encryptedDatabase";

describe("encryptedDatabase.getEncryptedAISettingsList", () => {
  it("将旧版单对象 ai_settings 兼容迁移为数组并持久化", async () => {
    vi.mocked(loadEncryptedData).mockResolvedValue({
      id: "s1",
      user_id: "u1",
      api_endpoint: "https://example.com",
      api_key: "k",
      model: "m",
      system_prompt: "p",
      created_at: "2020-01-01T00:00:00.000Z",
      updated_at: "2020-01-01T00:00:00.000Z",
    });

    const list = await getEncryptedAISettingsList("u1");

    expect(list).toHaveLength(1);
    expect(list[0]).toMatchObject({
      id: "s1",
      user_id: "u1",
      is_default: true,
    });
    expect(saveEncryptedData).toHaveBeenCalledTimes(1);
    expect(saveEncryptedData).toHaveBeenCalledWith(
      "u1",
      "ai_settings",
      expect.arrayContaining([expect.objectContaining({ id: "s1", is_default: true })])
    );
  });
});

