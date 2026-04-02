import * as admin from 'firebase-admin';
import { Request, Response, NextFunction } from 'express';
interface AuthenticatedRequest extends Request {
    user: admin.auth.DecodedIdToken;
}
/**
 * Firebase ID token doğrulayan middleware
 * Hata durumunda 401 döndürür, başarılı olduğunda req.user = decodedToken
 */
declare const authMiddleware: (req: AuthenticatedRequest, res: Response, next: NextFunction) => Promise<void>;
export default authMiddleware;
