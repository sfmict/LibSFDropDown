# <div align="center">LibSFDropDown</div>

It's a dropdown menu library.<br>
Includes standard options from UIDropDownMenu and some new ones like:

```lua
info.remove = [function(self)] -- The function that is called when you click the remove button
info.order = [function(self, delta)] -- The function that is called when you click the up or down arrow button
info.OnEnter = [function(self, arg1, arg2)] -- Handler OnEnter
info.OnLeave = [function(self, arg1, arg2)] -- Handler OnLeave
```

### Usage:

`local lsfdd = LibStub("LibSFDropDown-1.5")`

[API Documentation](https://github.com/sfmict/LibSFDropDown/wiki)
