import { AppError } from './app-error.js';

export class ConflictError extends AppError {
  constructor(message, code = 'CONFLICT', details = []) {
    super(409, code, message, details);
  }
}
