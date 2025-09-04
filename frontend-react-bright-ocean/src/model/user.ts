import type { BaseModel } from './base';

export interface UserModel extends BaseModel {
  email: string;
  name: string;
  roles: string[];
  picture: string;
  lastLogin: string;
  preferences?: Record<string, string | number | boolean>;
}

export type UserProfile = UserModel;