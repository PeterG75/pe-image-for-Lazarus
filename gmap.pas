{
  Generic Key-Value Map class. Items are ordered by Key.
}
unit gmap;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  grbtree;

type
  TMap<TKey, TValue> = class(TEnumerable < TPair < TKey, TValue >> )
  public type
    TCompareLess = reference to function(const A, B: TKey): boolean;
  private const
    SKeyDoesNotExist = 'Key does not exist.';
  private type
    TItem = record
      Pair: TPair<TKey, TValue>;
      Owner: TMap<TKey, TValue>;
      constructor Create(const K: TKey; const V: TValue;
        const Owner: TMap<TKey, TValue>);
    end;

    TItemTree = TRBTree<TItem>;

    TPairEnumerator = class(TEnumerator < TPair < TKey, TValue >> )
    private
      FMap: TMap<TKey, TValue>;
      FNode: TItemTree.TRBNodePtr;
    protected
      function DoGetCurrent: TPair<TKey, TValue>; override;
      function DoMoveNext: boolean; override;
    public
      constructor Create(const Map: TMap<TKey, TValue>);
    end;

  private
    FKeyComparer: TCompareLess;
    FItems: TItemTree;
    class function CompareItem(const A, B: TItem): boolean; static; inline;

    // Add new Key-Value pair or update existing Key with Value.
    procedure &Set(const Key: TKey; const Value: TValue);

    // Get Value by key.
    function Get(const Key: TKey): TValue;

    // Find node of item in RBTRree.
    function FindNodePtr(const Key: TKey): TItemTree.TRBNodePtr; inline;

    function GetCount: integer; inline;
  protected
    function DoGetEnumerator: TEnumerator<TPair<TKey, TValue>>; override;
  public
    constructor Create(const Comparer: TCompareLess);
    destructor Destroy; override;

    // Add new item.
    procedure Add(const Key: TKey; const Value: TValue); // inline; XE4 doesn't like the inline
    procedure Clear; inline;
    function ContainsKey(const Key: TKey): boolean; // inline; XE4 doesn't like the inline
    function TryGetValue(const Key: TKey; out Value: TValue): boolean;
    procedure Remove(const Key: TKey);

    property Items[const Key: TKey]: TValue read Get write &Set; default;
    property Count: integer read GetCount;
  end;

implementation

{ TMap<TKey, TValue> }

procedure TMap<TKey, TValue>.Add(const Key: TKey; const Value: TValue);
begin
  FItems.Add(TItem.Create(Key, Value, self));
end;

procedure TMap<TKey, TValue>.Clear;
begin
  FItems.Clear;
end;

class function TMap<TKey, TValue>.CompareItem(const A, B: TItem): boolean;
begin
  Result := A.Owner.FKeyComparer(A.Pair.Key, B.Pair.Key);
end;

constructor TMap<TKey, TValue>.Create(const Comparer: TCompareLess);
begin
  inherited Create;
  FKeyComparer := Comparer;
  FItems := TItemTree.Create(CompareItem);
end;

destructor TMap<TKey, TValue>.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TMap<TKey, TValue>.DoGetEnumerator: TEnumerator<TPair<TKey, TValue>>;
begin
  Result := TPairEnumerator.Create(self);
end;

function TMap<TKey, TValue>.FindNodePtr(const Key: TKey): TItemTree.TRBNodePtr;
begin
  Result := FItems.Find(TItem.Create(Key, Default (TValue), self));
end;

function TMap<TKey, TValue>.Get(const Key: TKey): TValue;
var
  Ptr: TItemTree.TRBNodePtr;
begin
  Ptr := FindNodePtr(Key);
  if Assigned(Ptr) then
    Result := Ptr^.K.Pair.Value
  else
    raise Exception.Create(SKeyDoesNotExist);
end;

function TMap<TKey, TValue>.GetCount: integer;
begin
  Result := FItems.Count;
end;

procedure TMap<TKey, TValue>.Remove(const Key: TKey);
var
  Ptr: TItemTree.TRBNodePtr;
begin
  Ptr := FindNodePtr(Key);
  if Assigned(Ptr) then
    FItems.Delete(Ptr);
end;

procedure TMap<TKey, TValue>.&Set(const Key: TKey; const Value: TValue);
var
  Ptr: TItemTree.TRBNodePtr;
begin
  Ptr := FindNodePtr(Key);
  if Assigned(Ptr) then
    Ptr^.K.Pair.Value := Value
  else
    Add(Key, Value);
end;

function TMap<TKey, TValue>.ContainsKey(const Key: TKey): boolean;
begin
  Result := FindNodePtr(Key) <> nil;
end;

function TMap<TKey, TValue>.TryGetValue(const Key: TKey;
  out Value: TValue): boolean;
var
  Ptr: TItemTree.TRBNodePtr;
begin
  Ptr := FindNodePtr(Key);
  Result := Assigned(Ptr);
  if Result then
    Value := Ptr^.K.Pair.Value
  else
    Value := Default (TValue);
end;

{ TMap<TKey, TValue>.TItem }

constructor TMap<TKey, TValue>.TItem.Create(const K: TKey; const V: TValue;
  const Owner: TMap<TKey, TValue>);
begin
  self.Pair.Key := K;
  self.Pair.Value := V;
  self.Owner := Owner;
end;

{ TMap<TKey, TValue>.TPairEnumerator }

constructor TMap<TKey, TValue>.TPairEnumerator.Create(
  const Map: TMap<TKey, TValue>);
begin
  FMap := Map;
  FNode := nil;
end;

function TMap<TKey, TValue>.TPairEnumerator.DoGetCurrent: TPair<TKey, TValue>;
begin
  Result := FNode^.K.Pair;
end;

function TMap<TKey, TValue>.TPairEnumerator.DoMoveNext: boolean;
begin
  if FNode = nil then
  begin
    FNode := FMap.FItems.First;
    Exit(True);
  end;
  Result := FMap.FItems.Next(FNode);
end;

end.