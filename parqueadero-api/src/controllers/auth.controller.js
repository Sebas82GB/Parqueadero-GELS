import * as authService from '../services/auth.service.js';

export async function login(req, res) {
  const { usuario, accessToken, refreshToken } = await authService.login(req.body);
  res.status(200).json({ usuario, accessToken, refreshToken });
}

export async function refresh(req, res) {
  const tokens = await authService.refresh(req.body.refreshToken);
  res.status(200).json(tokens);
}

export async function logout(req, res) {
  await authService.logout(req.body.refreshToken);
  res.status(204).send();
}

export async function me(req, res) {
  const usuario = await authService.me(req.user.id);
  res.status(200).json(usuario);
}
