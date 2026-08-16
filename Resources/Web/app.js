(() => {
    const bridge = window.webkit?.messageHandlers;
    const initial = window.__MENU_NOTE_INITIAL__ || { html: '' };
    const editor = document.querySelector('#editor');
    const saveStatus = document.querySelector('#save-status');
    const themeButton = document.querySelector('#theme-button');
    const awakeButton = document.querySelector('#awake-button');
    const linkPopover = document.querySelector('#link-popover');
    const linkInput = document.querySelector('#link-input');
    const linkConfirm = document.querySelector('#link-confirm');
    const colorPopover = document.querySelector('#color-popover');
    const colorCommandButton = document.querySelector('[data-command="color"]');
    const colorButtons = Array.from(colorPopover.querySelectorAll('[data-color]'));
    let saveTimer = null;
    let savedSelection = null;
    let savedColorSelection = null;

    const colorMarkers = {
        default: 'rgb(1, 2, 3)',
        pink: 'rgb(234, 118, 203)',
        mauve: 'rgb(136, 57, 239)',
        red: 'rgb(210, 15, 57)',
        peach: 'rgb(254, 100, 11)',
        green: 'rgb(64, 160, 43)',
        blue: 'rgb(30, 102, 245)',
        maroon: 'rgb(230, 69, 83)'
    };
    const legacyColorNames = { orange: 'peach', purple: 'mauve' };

    editor.innerHTML = typeof initial.html === 'string' ? initial.html : '';
    normalizeColorSpans();
    prepareTodoRows();
    setTheme(window.__MENU_NOTE_THEME__ === 'light' ? 'light' : 'dark', false);
    setAwakeEnabled(window.__MENU_NOTE_AWAKE__ === true);
    document.execCommand('styleWithCSS', false, false);
    requestAnimationFrame(() => focusEditorStart());

    document.querySelectorAll('[data-command]').forEach((button) => {
        button.addEventListener('mousedown', (event) => event.preventDefault());
        button.addEventListener('click', () => runCommand(button.dataset.command));
    });

    editor.addEventListener('input', () => {
        normalizeColorSpans();
        prepareTodoRows();
        scheduleSave();
        updateToolbarState();
    });
    editor.addEventListener('keydown', handleEditorKeyDown);
    editor.addEventListener('paste', handlePaste);
    editor.addEventListener('click', handleEditorClick);
    document.addEventListener('selectionchange', updateToolbarState);

    themeButton.addEventListener('click', () => setTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark', true));
    awakeButton.addEventListener('click', () => {
        const enabled = awakeButton.getAttribute('aria-pressed') !== 'true';
        setAwakeEnabled(enabled);
        bridge?.menuNoteAwake?.postMessage(enabled);
    });
    document.querySelector('#quit-button').addEventListener('click', () => {
        flushSave();
        bridge?.menuNoteQuit?.postMessage(true);
    });
    linkInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter') {
            event.preventDefault();
            confirmLink();
        }
        if (event.key === 'Escape') {
            event.preventDefault();
            closeLinkPopover();
        }
    });
    linkConfirm.addEventListener('click', confirmLink);
    colorButtons.forEach((button) => {
        button.addEventListener('mousedown', (event) => event.preventDefault());
        button.addEventListener('click', () => applyTextColor(button.dataset.color));
    });
    document.addEventListener('mousedown', (event) => {
        if (!event.target.closest('#link-popover') && !event.target.closest('[data-command="link"]')) linkPopover.hidden = true;
        if (!event.target.closest('#color-popover') && !event.target.closest('[data-command="color"]')) colorPopover.hidden = true;
    });

    function runCommand(command) {
        if (command === 'todo') {
            insertTodo();
        } else if (command === 'code') {
            toggleInlineCode();
        } else if (command === 'link') {
            openLinkPopover();
        } else if (command === 'color') {
            openColorPopover();
        } else if (command === 'quote') {
            toggleQuote();
        } else {
            document.execCommand(command, false);
            editor.focus();
            contentChanged();
        }
    }

    function handleEditorKeyDown(event) {
        if (event.metaKey && event.key.toLowerCase() === 'b') {
            event.preventDefault();
            runCommand('bold');
            return;
        }
        if (event.metaKey && event.key.toLowerCase() === 'i') {
            event.preventDefault();
            runCommand('italic');
            return;
        }
        if (event.metaKey && event.key.toLowerCase() === 'k') {
            event.preventDefault();
            openLinkPopover();
            return;
        }

        const todoText = todoTextAtSelection();
        if (!todoText) return;
        if (event.key === 'Enter' && !event.shiftKey && !event.metaKey && !event.altKey && !event.ctrlKey) {
            event.preventDefault();
            splitTodoRow(todoText);
        } else if (event.key === 'Backspace' && caretIsAtStart(todoText)) {
            event.preventDefault();
            convertTodoToParagraph(todoText.closest('.todo-row'));
        }
    }

    function handlePaste(event) {
        event.preventDefault();
        const text = event.clipboardData?.getData('text/plain') || '';
        document.execCommand('insertText', false, text);
    }

    function handleEditorClick(event) {
        const checkbox = event.target.closest('.todo-check');
        if (checkbox) {
            event.preventDefault();
            const row = checkbox.closest('.todo-row');
            const checked = row.dataset.checked !== 'true';
            row.dataset.checked = String(checked);
            checkbox.setAttribute('aria-checked', String(checked));
            checkbox.setAttribute('aria-label', checked ? '标记为未完成' : '标记为已完成');
            contentChanged();
            return;
        }
        if (event.target.closest('a')) event.preventDefault();
    }

    function insertTodo() {
        editor.focus();
        const selection = window.getSelection();
        const selectedText = selection?.toString().trim() || '';
        const lines = selectedText ? selectedText.split(/\n+/).filter(Boolean) : [''];
        const token = `todo-${Date.now().toString(36)}`;
        const rows = lines.map((line, index) => todoHTML(escapeHTML(line), false, index === lines.length - 1 ? token : '')).join('');
        document.execCommand('insertHTML', false, rows);
        prepareTodoRows();
        const target = editor.querySelector(`[data-focus-token="${token}"] .todo-text`);
        target?.closest('.todo-row')?.removeAttribute('data-focus-token');
        if (target) placeCaretAtEnd(target);
        contentChanged();
    }

    function splitTodoRow(todoText) {
        const selection = window.getSelection();
        if (!selection?.rangeCount) return;
        const range = selection.getRangeAt(0);
        if (!range.collapsed) range.deleteContents();

        if (!todoText.textContent.trim() && caretIsAtStart(todoText)) {
            convertTodoToParagraph(todoText.closest('.todo-row'));
            return;
        }

        const tailRange = document.createRange();
        tailRange.setStart(range.startContainer, range.startOffset);
        tailRange.setEnd(todoText, todoText.childNodes.length);
        const tail = tailRange.extractContents();
        ensureEditableContent(todoText);

        const newRow = createTodoRow(false);
        const newText = newRow.querySelector('.todo-text');
        newText.replaceChildren(tail);
        ensureEditableContent(newText);
        todoText.closest('.todo-row').after(newRow);
        placeCaretAtStart(newText);
        contentChanged();
    }

    function convertTodoToParagraph(row) {
        if (!row) return;
        const paragraph = document.createElement('div');
        const text = row.querySelector('.todo-text');
        while (text?.firstChild) paragraph.append(text.firstChild);
        ensureEditableContent(paragraph);
        row.replaceWith(paragraph);
        placeCaretAtStart(paragraph);
        contentChanged();
    }

    function createTodoRow(checked) {
        const wrapper = document.createElement('div');
        wrapper.innerHTML = todoHTML('', checked);
        return wrapper.firstElementChild;
    }

    function todoHTML(text, checked, focusToken = '') {
        const token = focusToken ? ` data-focus-token="${focusToken}"` : '';
        const safeText = text || '<br>';
        const label = checked ? '标记为未完成' : '标记为已完成';
        return [
            `<div class="todo-row" data-checked="${checked}"${token}>`,
            `<button class="todo-check" type="button" contenteditable="false" role="checkbox" aria-checked="${checked}" aria-label="${label}"></button>`,
            `<span class="todo-text">${safeText}</span></div>`
        ].join('');
    }

    function prepareTodoRows() {
        editor.querySelectorAll('.todo-row').forEach((row) => {
            row.dataset.checked = String(row.dataset.checked === 'true');
            const check = row.querySelector('.todo-check');
            if (check) {
                check.contentEditable = 'false';
                check.setAttribute('role', 'checkbox');
                check.setAttribute('aria-checked', row.dataset.checked);
                check.setAttribute('aria-label', row.dataset.checked === 'true' ? '标记为未完成' : '标记为已完成');
            }
            const text = row.querySelector('.todo-text');
            if (text) ensureEditableContent(text);
        });
    }

    function toggleInlineCode() {
        editor.focus();
        const selection = window.getSelection();
        if (!selection?.rangeCount) return;
        const range = selection.getRangeAt(0);
        const existing = closestFromNode(range.startContainer, 'code');
        if (existing && editor.contains(existing)) {
            const fragment = document.createDocumentFragment();
            while (existing.firstChild) fragment.append(existing.firstChild);
            existing.replaceWith(fragment);
        } else if (range.collapsed) {
            document.execCommand('insertHTML', false, '<code>代码</code>');
        } else {
            const code = document.createElement('code');
            code.append(range.extractContents());
            range.insertNode(code);
            selectContents(code);
        }
        contentChanged();
    }

    function toggleQuote() {
        editor.focus();
        const selection = window.getSelection();
        const quote = selection?.rangeCount ? closestFromNode(selection.anchorNode, 'blockquote') : null;
        document.execCommand('formatBlock', false, quote ? 'div' : 'blockquote');
        contentChanged();
    }

    function openLinkPopover() {
        const selection = window.getSelection();
        if (!selection?.rangeCount || !editor.contains(selection.anchorNode)) {
            editor.focus();
            return;
        }
        savedSelection = selection.getRangeAt(0).cloneRange();
        colorPopover.hidden = true;
        savedColorSelection = null;
        linkInput.value = '';
        linkPopover.hidden = false;
        requestAnimationFrame(() => linkInput.focus());
    }

    function confirmLink() {
        const rawValue = linkInput.value.trim();
        if (!rawValue || !savedSelection) {
            closeLinkPopover();
            return;
        }
        const href = /^https?:\/\//i.test(rawValue) ? rawValue : `https://${rawValue}`;
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(savedSelection);
        if (savedSelection.collapsed) {
            const anchor = document.createElement('a');
            anchor.href = href;
            anchor.textContent = href;
            savedSelection.insertNode(anchor);
            const afterLink = document.createRange();
            afterLink.setStartAfter(anchor);
            afterLink.collapse(true);
            replaceSelection(afterLink);
        } else {
            document.execCommand('createLink', false, href);
        }
        closeLinkPopover();
        editor.focus();
        contentChanged();
    }

    function closeLinkPopover() {
        linkPopover.hidden = true;
        savedSelection = null;
        editor.focus();
    }

    function openColorPopover() {
        const selection = window.getSelection();
        if (!selection?.rangeCount || !editor.contains(selection.anchorNode)) {
            editor.focus();
            return;
        }
        savedColorSelection = selection.getRangeAt(0).cloneRange();
        linkPopover.hidden = true;
        savedSelection = null;
        colorPopover.hidden = false;
        updateColorButtons(activeTextColor(selection.anchorNode));
    }

    function applyTextColor(colorName) {
        if (!savedColorSelection || !colorMarkers[colorName]) return;
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(savedColorSelection);
        document.execCommand('styleWithCSS', false, true);
        document.execCommand('foreColor', false, colorMarkers[colorName]);
        document.execCommand('styleWithCSS', false, false);
        normalizeColorSpans();
        colorPopover.hidden = true;
        savedColorSelection = null;
        editor.focus();
        contentChanged();
    }

    function normalizeColorSpans() {
        const markerEntries = Object.entries(colorMarkers).map(([name, value]) => [name, compactColor(value)]);
        editor.querySelectorAll('span[style*="color"]').forEach((span) => {
            const match = markerEntries.find(([, marker]) => compactColor(span.style.color) === marker);
            if (!match) return;
            Array.from(span.classList).filter((name) => name.startsWith('text-color-')).forEach((name) => span.classList.remove(name));
            span.classList.add(`text-color-${match[0]}`);
            span.style.removeProperty('color');
            if (!span.getAttribute('style')) span.removeAttribute('style');
        });
    }

    function compactColor(value) {
        return value.toLowerCase().replace(/\s/g, '');
    }

    function activeTextColor(node) {
        const colorElement = closestFromNode(node, '[class*="text-color-"]');
        const colorClass = Array.from(colorElement?.classList || []).find((name) => name.startsWith('text-color-'));
        const colorName = colorClass ? colorClass.replace('text-color-', '') : 'default';
        return legacyColorNames[colorName] || colorName;
    }

    function updateColorButtons(activeColor) {
        colorButtons.forEach((button) => button.setAttribute('aria-pressed', String(button.dataset.color === activeColor)));
    }

    function updateToolbarState() {
        const selection = window.getSelection();
        if (!selection?.rangeCount || !editor.contains(selection.anchorNode)) return;
        const states = {
            bold: document.queryCommandState('bold'),
            italic: document.queryCommandState('italic'),
            strikeThrough: document.queryCommandState('strikeThrough'),
            insertUnorderedList: document.queryCommandState('insertUnorderedList'),
            insertOrderedList: document.queryCommandState('insertOrderedList'),
            code: Boolean(closestFromNode(selection.anchorNode, 'code')),
            quote: Boolean(closestFromNode(selection.anchorNode, 'blockquote')),
            todo: Boolean(closestFromNode(selection.anchorNode, '.todo-row'))
        };
        Object.entries(states).forEach(([command, active]) => {
            document.querySelector(`[data-command="${command}"]`)?.setAttribute('aria-pressed', String(active));
        });
        const textColor = activeTextColor(selection.anchorNode);
        colorCommandButton.setAttribute('aria-pressed', String(textColor !== 'default'));
        colorCommandButton.dataset.activeColor = textColor;
        updateColorButtons(textColor);
    }

    function contentChanged() {
        editor.dispatchEvent(new Event('input', { bubbles: true }));
    }

    function scheduleSave() {
        saveStatus.innerHTML = '<i></i>正在保存';
        saveStatus.classList.add('saving');
        window.clearTimeout(saveTimer);
        saveTimer = window.setTimeout(flushSave, 180);
    }

    function flushSave() {
        window.clearTimeout(saveTimer);
        bridge?.menuNoteSave?.postMessage({ html: editor.innerHTML });
        saveStatus.innerHTML = '<i></i>已保存';
        saveStatus.classList.remove('saving');
    }

    function setTheme(theme, notifyHost) {
        document.documentElement.dataset.theme = theme;
        themeButton.setAttribute('aria-label', theme === 'dark' ? '切换为浅色模式' : '切换为深色模式');
        if (notifyHost) bridge?.menuNoteTheme?.postMessage(theme);
    }

    function setAwakeEnabled(enabled) {
        const isEnabled = Boolean(enabled);
        awakeButton.setAttribute('aria-pressed', String(isEnabled));
        awakeButton.setAttribute('aria-label', isEnabled ? '停止保持 Mac 唤醒' : '保持 Mac 唤醒');
        awakeButton.title = isEnabled ? '停止保持 Mac 唤醒' : '保持 Mac 唤醒（caffeinate）';
    }

    window.__MENU_NOTE_SET_AWAKE__ = setAwakeEnabled;

    function todoTextAtSelection() {
        const selection = window.getSelection();
        if (!selection?.rangeCount) return null;
        const text = closestFromNode(selection.anchorNode, '.todo-text');
        return text && editor.contains(text) ? text : null;
    }

    function closestFromNode(node, selector) {
        const element = node?.nodeType === Node.ELEMENT_NODE ? node : node?.parentElement;
        return element?.closest(selector) || null;
    }

    function caretIsAtStart(element) {
        const selection = window.getSelection();
        if (!selection?.rangeCount || !selection.isCollapsed) return false;
        const before = selection.getRangeAt(0).cloneRange();
        before.selectNodeContents(element);
        before.setEnd(selection.anchorNode, selection.anchorOffset);
        return before.toString().length === 0;
    }

    function ensureEditableContent(element) {
        if (!element.textContent && !element.querySelector('br')) element.append(document.createElement('br'));
    }

    function placeCaretAtStart(element) {
        const range = document.createRange();
        range.selectNodeContents(element);
        range.collapse(true);
        replaceSelection(range);
    }

    function placeCaretAtEnd(element) {
        const range = document.createRange();
        range.selectNodeContents(element);
        range.collapse(false);
        replaceSelection(range);
    }

    function selectContents(element) {
        const range = document.createRange();
        range.selectNodeContents(element);
        replaceSelection(range);
    }

    function replaceSelection(range) {
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        editor.focus();
    }

    function focusEditorStart() {
        editor.focus();
        if (!editor.childNodes.length) return;
        placeCaretAtStart(editor.firstElementChild || editor);
    }

    function escapeHTML(value) {
        return value.replace(/[&<>"']/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' })[character]);
    }
})();
