module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.js', '**/*.test.js'],
  collectCoverageFrom: [
    'src/**/*.{ts,js}',
    '!src/**/*.test.{ts,js}',
    '!src/**/*.spec.{ts,js}',
    '!src/**/*.d.ts',
    '!node_modules/**',
    '!coverage/**',
    '!jest.config.js',
    '!__tests__/**',
    '!test/**'
  ],
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: ['<rootDir>/test/setup.js'],
  testTimeout: 30000,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
  moduleFileExtensions: ['js', 'ts'],
  testPathIgnorePatterns: ['/node_modules/', '/lib/'],
  coverageDirectory: './coverage',
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  // Support for both TypeScript and JavaScript files
  transform: {
    '^.+\.(ts|tsx)$': ['ts-jest', {
      tsconfig: {
        compilerOptions: {
          module: 'commonjs',
          target: 'es2017'
        }
      }
    }],
    '^.+\.(js|jsx)$': 'babel-jest'
  },
  // Module resolution
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@test/(.*)$': '<rootDir>/test/$1'
  },
  // Test environment setup
  testEnvironmentOptions: {
    node: {
      global: true
    }
  },
  // Ignore patterns
  testPathIgnorePatterns: [
    '/node_modules/',
    '/lib/',
    '/coverage/'
  ],
  // Force exit after tests
  forceExit: true,
  // Detect open handles
  detectOpenHandles: true
};
