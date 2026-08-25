import { AppError } from './app-error.js';

export class NotFoundError extends AppError {
  constructor(message, code = 'NOT_FOUND', details = []) {
    super(404, code, message, details);
  }
}
