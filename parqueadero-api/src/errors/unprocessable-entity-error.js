import { AppError } from './app-error.js';

export class UnprocessableEntityError extends AppError {
  constructor(message, code = 'UNPROCESSABLE_ENTITY', details = []) {
    super(422, code, message, details);
  }
}
