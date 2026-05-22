class Either<L, R> {
  final L? _left;
  final R? _right;

  const Either._(this._left, this._right);

  const Either.left(L value) : this._(value, null);
  const Either.right(R value) : this._(null, value);

  bool get isLeft => _left != null;
  bool get isRight => _right != null;

  L get left {
    assert(isLeft, 'Tried to access Left on a Right');
    return _left as L;
  }

  R get right {
    assert(isRight, 'Tried to access Right on a Left');
    return _right as R;
  }
}
