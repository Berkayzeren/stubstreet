// Mock Firebase admin
const mockVerifyIdToken = jest.fn();
jest.mock('firebase-admin', () => ({
  auth: () => ({
    verifyIdToken: mockVerifyIdToken
  })
}));

const authMiddleware = require('../../middleware/authMiddleware');

describe('authMiddleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      headers: {}
    };
    res = {
      status: jest.fn(() => res),
      json: jest.fn()
    };
    next = jest.fn();
    
    // Mock'ları temizle
    jest.clearAllMocks();
    mockVerifyIdToken.mockClear();
  });

  describe('Başarılı durumlar', () => {
    test('Geçerli token ile kullanıcı doğrulaması', async () => {
      // Arrange
      const mockToken = 'valid-token';
      const mockDecodedToken = {
        uid: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User'
      };

      req.headers.authorization = `Bearer ${mockToken}`;
      mockVerifyIdToken.mockResolvedValue(mockDecodedToken);

      // Act
      await authMiddleware(req, res, next);

      // Assert
      expect(mockVerifyIdToken).toHaveBeenCalledWith(mockToken);
      expect(req.user).toEqual(mockDecodedToken);
      expect(next).toHaveBeenCalledWith();
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('Hata durumları', () => {
    test('Authorization header yoksa 401 hatası', async () => {
      // Act
      await authMiddleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalledWith(expect.objectContaining({
        message: 'Authorization header gerekli',
        status: 401
      }));
    });

    test('Geçersiz token ile 401 hatası', async () => {
      // Arrange
      const mockToken = 'invalid-token';
      req.headers.authorization = `Bearer ${mockToken}`;
      mockVerifyIdToken.mockRejectedValue(new Error('Invalid token'));

      // Act
      await authMiddleware(req, res, next);

      // Assert
      expect(mockVerifyIdToken).toHaveBeenCalledWith(mockToken);
      expect(next).toHaveBeenCalledWith(expect.objectContaining({
        message: 'Geçersiz token',
        status: 401
      }));
    });
  });
});
