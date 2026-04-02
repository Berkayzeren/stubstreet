import { Request, Response, NextFunction } from 'express';
interface CustomError extends Error {
    status?: number;
    statusCode?: number;
    code?: string;
    validationErrors?: any[];
}
/**
 * Global error handler middleware
 * Tüm hataları yakalar ve standart format ile döndürür
 */
declare const errorHandler: (err: CustomError, req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>>;
/**
 * Validation middleware - express-validator hatalarını yakalar
 */
declare const validationHandler: (req: Request, res: Response, next: NextFunction) => void;
/**
 * 404 handler - Route bulunamadığında
 */
declare const notFoundHandler: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Async error wrapper - async fonksiyonlardaki hataları yakalar
 */
declare const asyncHandler: (fn: Function) => (req: Request, res: Response, next: NextFunction) => void;
export { errorHandler, validationHandler, notFoundHandler, asyncHandler };
