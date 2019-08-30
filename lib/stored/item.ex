defprotocol Stored.Item do
  @spec key(struct) :: term
  def key(item)
end
