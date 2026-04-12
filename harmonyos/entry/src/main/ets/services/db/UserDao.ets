// 用户表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { User } from '../../models/User'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { BaseDao } from './BaseDao'

export class UserDao {
  private static readonly baseDao: BaseDao<User> =
    new BaseDao<User>(DatabaseSchema.TABLE_USERS, UserDao.fromResultSet)

  static async insert(email: string, passwordHash: string, role: string = 'user'): Promise<User> {
    try {
      const user = new User()
      user.id = generateId()
      user.email = email
      user.passwordHash = passwordHash
      user.role = role
      user.createdAt = getTimestamp()

      const bucket: relationalStore.ValuesBucket = {
        'id': user.id,
        'email': user.email,
        'password_hash': user.passwordHash,
        'role': user.role,
        'created_at': user.createdAt
      }
      await UserDao.baseDao.getStore().insert(DatabaseSchema.TABLE_USERS, bucket)
      return user
    } catch (err) {
      throw new Error(`Failed to insert user: ${String(err)}`)
    }
  }

  static async findByEmail(email: string): Promise<User | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_USERS)
      predicates.equalTo('email', email)
      return await UserDao.baseDao.queryFirst(predicates, 'UserDao.findByEmail')
    } catch (err) {
      throw new Error(`Failed to find user by email: ${String(err)}`)
    }
  }

  static async findById(id: string): Promise<User | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_USERS)
      predicates.equalTo('id', id)
      return await UserDao.baseDao.queryFirst(predicates, 'UserDao.findById')
    } catch (err) {
      throw new Error(`Failed to find user by id: ${String(err)}`)
    }
  }

  static async findAll(): Promise<User[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_USERS)
      return await UserDao.baseDao.queryList(predicates, 'UserDao.findAll')
    } catch (err) {
      throw new Error(`Failed to find all users: ${String(err)}`)
    }
  }

  static async count(): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_USERS)
      return await UserDao.baseDao.count(predicates, 'UserDao.count')
    } catch (err) {
      throw new Error(`Failed to count users: ${String(err)}`)
    }
  }

  static async updateRole(id: string, role: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_USERS)
      predicates.equalTo('id', id)
      const bucket: relationalStore.ValuesBucket = { 'role': role }
      await UserDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update user role: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_USERS)
      predicates.equalTo('id', id)
      await UserDao.baseDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete user: ${String(err)}`)
    }
  }

  private static fromResultSet(rs: relationalStore.ResultSet): User {
    try {
      const user = new User()
      user.id = rs.getString(rs.getColumnIndex('id'))
      user.email = rs.getString(rs.getColumnIndex('email'))
      user.passwordHash = rs.getString(rs.getColumnIndex('password_hash'))
      user.role = rs.getString(rs.getColumnIndex('role'))
      user.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      return user
    } catch (err) {
      throw new Error(`Failed to map user result set: ${String(err)}`)
    }
  }
}
