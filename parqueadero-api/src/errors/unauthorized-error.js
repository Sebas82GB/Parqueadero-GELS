import { AppError } from './app-error.js';

export class UnauthorizedError extends AppError {
  constructor(message, code = 'UNAUTHORIZED', details = []) {
    super(401, code, message, details);
  }
}
