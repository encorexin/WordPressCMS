import { legacyDb } from "./legacyDatabase";

export { generateId, getTimestamp } from "./models";
export type { LocalUser } from "./models";

// 阶段 07 起，database.ts 只保留认证所需的 users 表入口。
const db = {
    users: legacyDb.users,
};

export { db };

