export function toSkipTake(page, perPage) {
  return { skip: (page - 1) * perPage, take: perPage };
}

export function sendPage(res, items, { page, perPage, total }) {
  res.status(200).json({ data: items, meta: { page, perPage, total } });
}
