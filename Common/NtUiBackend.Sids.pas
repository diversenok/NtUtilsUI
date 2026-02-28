unit NtUiBackend.Sids;

interface

uses
  NtUtilsUI.DevirtualizedTree, NtUtils.Lsa.Sid;

type
  ISidNode = interface (INodeProvider)
    ['{2366E5CA-95BF-4F5D-B412-5D733EB3B9F8}']
    function GetSidName: TTranslatedName;
    property SidName: TTranslatedName read GetSidName;
  end;

implementation

end.
