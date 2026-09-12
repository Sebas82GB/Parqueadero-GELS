import * as ticketService from '../services/ticket.service.js';
import { sendPage } from '../utils/paginacion.util.js';

export async function listarTickets(req, res) {
  const { tickets, total, page, perPage } = await ticketService.listarTickets(req.query);
  sendPage(res, tickets, { page, perPage, total });
}

export async function obtenerTicketPorId(req, res) {
  const ticket = await ticketService.obtenerTicketPorId(req.params.id);
  res.status(200).json(ticket);
}

export async function registrarEntrada(req, res) {
  const ticket = await ticketService.registrarEntrada(req.body, { operadorId: req.user.id });
  res.status(201).json(ticket);
}

export async function previsualizarCobro(req, res) {
  const preview = await ticketService.previsualizarCobro(req.params.id);
  res.status(200).json(preview);
}

export async function registrarSalida(req, res) {
  const ticket = await ticketService.registrarSalida(req.params.id, req.body, {
    operadorId: req.user.id,
  });
  res.status(200).json(ticket);
}

export async function anularTicket(req, res) {
  const ticket = await ticketService.anularTicket(req.params.id, req.body, {
    usuarioId: req.user.id,
  });
  res.status(200).json(ticket);
}

export async function entregarTicket(req, res) {
  const ticket = await ticketService.entregarTicket(req.params.id, { usuarioId: req.user.id });
  res.status(200).json(ticket);
}
