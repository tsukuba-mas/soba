proc tail*[T](xs: seq[T], n: int): seq[T] = 
  if xs.len <= n:
    xs
  else:
    xs[(xs.len - n)..<xs.len]