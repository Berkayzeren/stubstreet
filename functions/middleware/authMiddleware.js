const admin = require('firebase-admin');

/**
 * Firebase ID token doğrulayan middleware
 * Hata durumunda 401 döndürür, başarılı olduğunda req.user = decodedToken
 */
const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const error = new Error('Authorization header gerekli');
      error.status = 401;
      return next(error);
    }
    
    const idToken = authHeader.split('Bearer ')[1];
    
    if (!idToken) {
      const error = new Error('ID token gerekli');
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
    error.status = 401;
    error.message = 'Geçersiz token';
    next(error);
  }
};

module.exports = authMiddleware;
