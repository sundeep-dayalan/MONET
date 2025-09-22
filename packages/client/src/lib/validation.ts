/**
 * Input validation utilities using Zod
 * Provides type-safe validation for all user inputs
 */

import { z } from 'zod';

// Base validation schemas
export const emailSchema = z
  .string()
  .email('Please enter a valid email address')
  .min(1, 'Email is required');

export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
  .regex(/[0-9]/, 'Password must contain at least one number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character');

export const nameSchema = z
  .string()
  .min(1, 'Name is required')
  .max(100, 'Name must be less than 100 characters')
  .regex(/^[a-zA-Z\s'-]+$/, 'Name can only contain letters, spaces, hyphens, and apostrophes');

// User-related schemas
export const userCreateSchema = z.object({
  email: emailSchema,
  name: nameSchema,
  password: passwordSchema,
});

export const userUpdateSchema = z.object({
  name: nameSchema.optional(),
  email: emailSchema.optional(),
}).refine(data => Object.keys(data).length > 0, {
  message: 'At least one field must be provided for update',
});

// Plaid-related schemas
export const plaidAccountSchema = z.object({
  account_id: z.string().min(1, 'Account ID is required'),
  name: z.string().min(1, 'Account name is required'),
  type: z.enum(['depository', 'credit', 'loan', 'investment', 'other']),
  subtype: z.string().optional(),
});

export const plaidTransactionSchema = z.object({
  transaction_id: z.string().min(1, 'Transaction ID is required'),
  account_id: z.string().min(1, 'Account ID is required'),
  amount: z.number().finite('Amount must be a valid number'),
  date: z.string().refine(
    (date) => !isNaN(Date.parse(date)),
    'Invalid date format'
  ),
  description: z.string().min(1, 'Description is required'),
});

// API response schemas
export const apiErrorSchema = z.object({
  detail: z.string(),
  status_code: z.number().optional(),
});

export const tokenSchema = z.object({
  access_token: z.string().min(1, 'Access token is required'),
  token_type: z.string().default('bearer'),
  expires_in: z.number().positive().optional(),
});

// Environment validation
export const envSchema = z.object({
  VITE_API_BASE_URL: z.string().url('API base URL must be a valid URL'),
  VITE_APP_ENV: z.enum(['development', 'staging', 'production']).default('development'),
});

// Validation utility functions
export class ValidationHelper {
  /**
   * Safely parse and validate data with detailed error reporting
   */
  static safeValidate<T>(
    schema: z.ZodSchema<T>,
    data: unknown,
    context?: string
  ): { success: true; data: T } | { success: false; errors: string[] } {
    try {
      const result = schema.safeParse(data);
      
      if (result.success) {
        return { success: true, data: result.data };
      }
      
      const errors = result.error.errors.map(err => 
        `${err.path.join('.')}: ${err.message}`
      );
      
      return { success: false, errors };
    } catch (error) {
      const errorMessage = context 
        ? `Validation error in ${context}: ${error instanceof Error ? error.message : 'Unknown error'}`
        : `Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`;
      
      return { success: false, errors: [errorMessage] };
    }
  }

  /**
   * Validate API response data
   */
  static validateApiResponse<T>(
    schema: z.ZodSchema<T>,
    response: unknown,
    endpoint?: string
  ): T {
    const result = this.safeValidate(schema, response, endpoint);
    
    if (!result.success) {
      throw new Error(`API response validation failed${endpoint ? ` for ${endpoint}` : ''}: ${result.errors.join(', ')}`);
    }
    
    return result.data;
  }

  /**
   * Sanitize string input to prevent XSS
   */
  static sanitizeString(input: string): string {
    return input
      .replace(/[<>]/g, '') // Remove potential HTML tags
      .replace(/javascript:/gi, '') // Remove javascript: protocol
      .replace(/on\w+=/gi, '') // Remove event handlers
      .trim();
  }

  /**
   * Validate and sanitize form data
   */
  static sanitizeFormData<T extends Record<string, any>>(data: T): T {
    const sanitized = { ...data };
    
    for (const [key, value] of Object.entries(sanitized)) {
      if (typeof value === 'string') {
        sanitized[key] = this.sanitizeString(value);
      }
    }
    
    return sanitized;
  }
}

// Export types for use in components
export type UserCreateInput = z.infer<typeof userCreateSchema>;
export type UserUpdateInput = z.infer<typeof userUpdateSchema>;
export type PlaidAccount = z.infer<typeof plaidAccountSchema>;
export type PlaidTransaction = z.infer<typeof plaidTransactionSchema>;
export type TokenData = z.infer<typeof tokenSchema>;
export type ApiError = z.infer<typeof apiErrorSchema>;