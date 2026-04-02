import * as admin from 'firebase-admin';
import { Request, Response, NextFunction } from 'express';

interface AuthenticatedRequest extends Request {
  user: admin.auth.DecodedIdToken;
}

interface AuthError extends Error {
  status?: number;
}

/**
 * Firebase ID token doğrulayan middleware
 * Hata durumunda 401 döndürür, başarılı olduğunda req.user = decodedToken
 */
const authMiddleware = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const error: AuthError = new Error('Authorization header gerekli');
      error.status = 401;
      return next(error);
    }
    
    const idToken = authHeader.split('Bearer ')[1];
    
    if (!idToken) {
      const error: AuthError = new Error('ID token gerekli');
      error.status = 401;
      return next(error);
    }
    
    // Firebase ID token doğrulama
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Başarılı olduğunda req.user = decodedToken
    req.user = decodedToken;
    
    next();
  } catch (error) {
    console.error('Token doğrulama hatası:', error);
    
    // Hata durumunda next(error) ile global error handler'a gönder
    const authError = error as AuthError;
    authError.status = 401;
    authError.message = 'Geçersiz token';
    next(authError);
  }
};

export default authMiddleware;
