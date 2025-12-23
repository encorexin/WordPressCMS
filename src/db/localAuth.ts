import bcrypt from 'bcryptjs';
import { db, generateId, getTimestamp, type LocalUser } from './database';
export type { LocalUser } from './database';

// Session key in localStorage
const SESSION_KEY = 'wordpress_cms_session';
const SALT_ROUNDS = 10;

// 获取当前会话用户
export function getCurrentUser(): LocalUser | null {
    try {
        const session = localStorage.getItem(SESSION_KEY);
        if (!session) return null;
        return JSON.parse(session) as LocalUser;
    } catch {
        return null;
    }
}

// 设置会话
function setSession(user: LocalUser): void {
    // 不存储密码哈希到 session
    const sessionUser = { ...user, password_hash: '' };
    localStorage.setItem(SESSION_KEY, JSON.stringify(sessionUser));
}

// 清除会话
export function clearSession(): void {
    localStorage.removeItem(SESSION_KEY);
}

// 用户注册
export async function register(email: string, password: string): Promise<{ user: LocalUser | null; error: string | null }> {
    try {
        // 检查邮箱是否已存在
        const existingUser = await db.users.where('email').equals(email).first();
        if (existingUser) {
            return { user: null, error: '该邮箱已注册' };
        }

        // 检查是否是第一个用户（设为管理员）
        const userCount = await db.users.count();
        const role = userCount === 0 ? 'admin' : 'user';

        // 加密密码
        const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

        // 创建用户
        const newUser: LocalUser = {
            id: generateId(),
            email,
            password_hash,
            role,
            created_at: getTimestamp(),
        };

        await db.users.add(newUser);

        // 设置会话
        setSession(newUser);

        return { user: newUser, error: null };
    } catch (error) {
        console.error('注册失败:', error);
        return { user: null, error: '注册失败，请重试' };
    }
}

// 用户登录
export async function login(email: string, password: string): Promise<{ user: LocalUser | null; error: string | null }> {
    try {
        // 查找用户
        const user = await db.users.where('email').equals(email).first();
        if (!user) {
            return { user: null, error: '邮箱或密码错误' };
        }

        // 验证密码
        const isValid = await bcrypt.compare(password, user.password_hash);
        if (!isValid) {
            return { user: null, error: '邮箱或密码错误' };
        }

        // 设置会话
        setSession(user);

        return { user, error: null };
    } catch (error) {
        console.error('登录失败:', error);
        return { user: null, error: '登录失败，请重试' };
    }
}

// 登出
export function logout(): void {
    clearSession();
}

// 检查是否已登录
export function isAuthenticated(): boolean {
    return getCurrentUser() !== null;
}

// 获取用户角色
export function getUserRole(): 'user' | 'admin' | null {
    const user = getCurrentUser();
    return user?.role ?? null;
}

// 刷新会话（从数据库重新加载用户信息）
export async function refreshSession(): Promise<LocalUser | null> {
    const currentUser = getCurrentUser();
    if (!currentUser) return null;

    const user = await db.users.get(currentUser.id);
    if (user) {
        setSession(user);
        return user;
    }

    clearSession();
    return null;
}
