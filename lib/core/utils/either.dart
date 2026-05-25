class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;

  const Either._(this._left, this._right, this._isLeft);

  const Either.left(L value) : this._(value, null, true);
  const Either.right(R value) : this._(null, value, false);

  bool get isLeft => _isLeft;
  bool get isRight => !_isLeft;

  L get left {
    assert(isLeft, 'Tried to access Left on a Right');
    return _left as L;
  }

  R get right {
    assert(isRight, 'Tried to access Right on a Left');
    return _right as R;
  }
}
