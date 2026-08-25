import { AppError } from './app-error.js';

export class ValidationError extends AppError {
  constructor(message, code = 'VALIDATION_ERROR', details = []) {
    super(400, code, message, details);
  }
}
