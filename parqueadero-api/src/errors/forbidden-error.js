import { AppError } from './app-error.js';

export class ForbiddenError extends AppError {
  constructor(message, code = 'FORBIDDEN', details = []) {
    super(403, code, message, details);
  }
}
