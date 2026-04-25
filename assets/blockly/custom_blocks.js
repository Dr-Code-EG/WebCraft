// Custom Blockly blocks for WebCraft (DOM, browser, HTTP, event helpers)
// and their JavaScript code generators.
(function () {
  if (typeof Blockly === 'undefined') return;
  const JS = Blockly.JavaScript;
  const Order = JS.ORDER_ATOMIC;
  const Func = JS.ORDER_FUNCTION_CALL;

  // ------- DOM -------
  Blockly.Blocks['dom_get_value'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('قيمة العنصر / value of element id')
          .appendField(new Blockly.FieldTextInput('myInput'), 'ID');
      this.setOutput(true, 'String');
      this.setColour(20);
    }
  };
  JS['dom_get_value'] = function (block) {
    const id = block.getFieldValue('ID');
    return [`(document.getElementById(${JSON.stringify(id)}) ? document.getElementById(${JSON.stringify(id)}).value : '')`, Func];
  };

  Blockly.Blocks['dom_set_text'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('عيّن نص العنصر / set text of #')
          .appendField(new Blockly.FieldTextInput('myEl'), 'ID');
      this.appendValueInput('VAL').setCheck(null).appendField('إلى / to');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };
  JS['dom_set_text'] = function (block) {
    const id = block.getFieldValue('ID');
    const val = JS.valueToCode(block, 'VAL', Order) || "''";
    return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.textContent = ${val}; }\n`;
  };

  Blockly.Blocks['dom_set_html'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('عيّن HTML للعنصر / set HTML of #')
          .appendField(new Blockly.FieldTextInput('myEl'), 'ID');
      this.appendValueInput('VAL').setCheck(null).appendField('إلى / to');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };
  JS['dom_set_html'] = function (block) {
    const id = block.getFieldValue('ID');
    const val = JS.valueToCode(block, 'VAL', Order) || "''";
    return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.innerHTML = ${val}; }\n`;
  };

  Blockly.Blocks['dom_set_style'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('عيّن نمط #')
          .appendField(new Blockly.FieldTextInput('myEl'), 'ID')
          .appendField('style')
          .appendField(new Blockly.FieldTextInput('color'), 'PROP');
      this.appendValueInput('VAL').setCheck(null).appendField('=');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };
  JS['dom_set_style'] = function (block) {
    const id = block.getFieldValue('ID');
    const prop = block.getFieldValue('PROP');
    const val = JS.valueToCode(block, 'VAL', Order) || "''";
    const camel = prop.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
    return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.style.${camel} = ${val}; }\n`;
  };

  Blockly.Blocks['dom_add_class'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('أضف صنف لـ / add class to #')
          .appendField(new Blockly.FieldTextInput('myEl'), 'ID')
          .appendField(new Blockly.FieldTextInput('active'), 'CLS');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };
  JS['dom_add_class'] = function (block) {
    const id = block.getFieldValue('ID');
    const cls = block.getFieldValue('CLS');
    return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.classList.add(${JSON.stringify(cls)}); }\n`;
  };

  Blockly.Blocks['dom_remove_class'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('احذف صنف من / remove class from #')
          .appendField(new Blockly.FieldTextInput('myEl'), 'ID')
          .appendField(new Blockly.FieldTextInput('active'), 'CLS');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(20);
    }
  };
  JS['dom_remove_class'] = function (block) {
    const id = block.getFieldValue('ID');
    const cls = block.getFieldValue('CLS');
    return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.classList.remove(${JSON.stringify(cls)}); }\n`;
  };

  function visToggleBlock(name, label, value) {
    Blockly.Blocks[name] = {
      init: function () {
        this.appendDummyInput()
            .appendField(label)
            .appendField(new Blockly.FieldTextInput('myEl'), 'ID');
        this.setPreviousStatement(true, null);
        this.setNextStatement(true, null);
        this.setColour(20);
      }
    };
    JS[name] = function (block) {
      const id = block.getFieldValue('ID');
      if (value === 'toggle') {
        return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.style.display = (el_.style.display === 'none' ? '' : 'none'); }\n`;
      }
      return `{ const el_ = document.getElementById(${JSON.stringify(id)}); if (el_) el_.style.display = ${JSON.stringify(value)}; }\n`;
    };
  }
  visToggleBlock('dom_show', 'أظهر / show #', '');
  visToggleBlock('dom_hide', 'أخفِ / hide #', 'none');
  visToggleBlock('dom_toggle', 'بدّل ظهور / toggle #', 'toggle');

  // ------- Browser -------
  Blockly.Blocks['browser_alert'] = {
    init: function () {
      this.appendValueInput('MSG').setCheck(null).appendField('alert');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(65);
    }
  };
  JS['browser_alert'] = function (block) {
    const msg = JS.valueToCode(block, 'MSG', Order) || "''";
    return `alert(${msg});\n`;
  };

  Blockly.Blocks['browser_console_log'] = {
    init: function () {
      this.appendValueInput('MSG').setCheck(null).appendField('console.log');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(65);
    }
  };
  JS['browser_console_log'] = function (block) {
    const msg = JS.valueToCode(block, 'MSG', Order) || "''";
    return `console.log(${msg});\n`;
  };

  Blockly.Blocks['browser_navigate'] = {
    init: function () {
      this.appendValueInput('URL').setCheck(null).appendField('navigate to');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(65);
    }
  };
  JS['browser_navigate'] = function (block) {
    const url = JS.valueToCode(block, 'URL', Order) || "''";
    return `window.location.href = ${url};\n`;
  };

  Blockly.Blocks['browser_reload'] = {
    init: function () {
      this.appendDummyInput().appendField('reload page');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(65);
    }
  };
  JS['browser_reload'] = function () {
    return 'window.location.reload();\n';
  };

  Blockly.Blocks['browser_storage_set'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('localStorage[')
          .appendField(new Blockly.FieldTextInput('key'), 'KEY')
          .appendField('] =');
      this.appendValueInput('VAL').setCheck(null);
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(65);
    }
  };
  JS['browser_storage_set'] = function (block) {
    const key = block.getFieldValue('KEY');
    const val = JS.valueToCode(block, 'VAL', Order) || "''";
    return `localStorage.setItem(${JSON.stringify(key)}, String(${val}));\n`;
  };

  Blockly.Blocks['browser_storage_get'] = {
    init: function () {
      this.appendDummyInput()
          .appendField('localStorage[')
          .appendField(new Blockly.FieldTextInput('key'), 'KEY')
          .appendField(']');
      this.setOutput(true, 'String');
      this.setColour(65);
    }
  };
  JS['browser_storage_get'] = function (block) {
    const key = block.getFieldValue('KEY');
    return [`(localStorage.getItem(${JSON.stringify(key)}) || '')`, Func];
  };

  // ------- HTTP -------
  Blockly.Blocks['http_fetch'] = {
    init: function () {
      this.appendValueInput('URL').setCheck(null).appendField('GET fetch');
      this.appendStatementInput('THEN').appendField('then text →').appendField(new Blockly.FieldVariable('response'), 'VAR');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(290);
    }
  };
  JS['http_fetch'] = function (block) {
    const url = JS.valueToCode(block, 'URL', Order) || "''";
    const v = JS.nameDB_.getName(block.getFieldValue('VAR'), Blockly.Names.NameType.VARIABLE);
    const inner = JS.statementToCode(block, 'THEN');
    return `fetch(${url}).then(r => r.text()).then(${v} => {\n${inner}});\n`;
  };

  Blockly.Blocks['http_post'] = {
    init: function () {
      this.appendValueInput('URL').setCheck(null).appendField('POST fetch');
      this.appendValueInput('BODY').setCheck(null).appendField('body');
      this.appendStatementInput('THEN').appendField('then text →').appendField(new Blockly.FieldVariable('response'), 'VAR');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(290);
    }
  };
  JS['http_post'] = function (block) {
    const url = JS.valueToCode(block, 'URL', Order) || "''";
    const body = JS.valueToCode(block, 'BODY', Order) || "''";
    const v = JS.nameDB_.getName(block.getFieldValue('VAR'), Blockly.Names.NameType.VARIABLE);
    const inner = JS.statementToCode(block, 'THEN');
    return `fetch(${url}, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(${body}) }).then(r => r.text()).then(${v} => {\n${inner}});\n`;
  };

  // ------- Event helpers (only meaningful inside event handlers) -------
  Blockly.Blocks['event_target'] = {
    init: function () {
      this.appendDummyInput().appendField('event.target');
      this.setOutput(true, null);
      this.setColour(350);
    }
  };
  JS['event_target'] = function () {
    return ['event.target', Order];
  };

  Blockly.Blocks['event_prevent_default'] = {
    init: function () {
      this.appendDummyInput().appendField('preventDefault()');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(350);
    }
  };
  JS['event_prevent_default'] = function () {
    return 'if (typeof event !== "undefined") event.preventDefault();\n';
  };
})();
