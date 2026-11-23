.pragma library

// Small math evaluator for the launcher. A hand-written recursive-descent
// parser, so typed text is never executed as JavaScript.
//
//   numbers      12, 3.5, 3,5 (comma decimal), 1e3
//   operators    + - * / % ^ (power, right-associative), ×, ÷, implicit
//                multiplication: 2(3+4), 2pi
//   functions    sqrt cbrt abs round floor ceil ln log log2 exp sin cos tan
//                asin acos atan (radians)
//   constants    pi π e
//   percent      "200 * 15%" = 30; "200 + 15%" = 230 (adds 15 % of 200)

const FUNCTIONS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, round: Math.round,
    floor: Math.floor, ceil: Math.ceil, ln: Math.log, log: Math.log10,
    log2: Math.log2, exp: Math.exp, sin: Math.sin, cos: Math.cos, tan: Math.tan,
    asin: Math.asin, acos: Math.acos, atan: Math.atan
};
const CONSTANTS = { pi: Math.PI, "π": Math.PI, e: Math.E };

function tokenize(text) {
    const tokens = [];
    let i = 0;
    while (i < text.length) {
        const c = text[i];
        if (/\s/.test(c)) {
            i++;
            continue;
        }
        const number = text.slice(i).match(/^(\d+([.,]\d+)?|[.,]\d+)([eE][+-]?\d+)?/);
        if (number) {
            tokens.push({ type: "num", value: Number(number[0].replace(",", ".")) });
            i += number[0].length;
            continue;
        }
        const word = text.slice(i).match(/^([a-zA-Z]+\d*|π)/);
        if (word) {
            tokens.push({ type: "word", value: word[0].toLowerCase() });
            i += word[0].length;
            continue;
        }
        const op = { "×": "*", "÷": "/", "−": "-" }[c] ?? c;
        if ("+-*/%^()".includes(op)) {
            tokens.push({ type: "op", value: op });
            i++;
            continue;
        }
        return null; // unknown character: not a math expression
    }
    return tokens;
}

function Parser(tokens) {
    this.tokens = tokens;
    this.pos = 0;
}

Parser.prototype.peek = function () { return this.tokens[this.pos]; };
Parser.prototype.next = function () { return this.tokens[this.pos++]; };
Parser.prototype.isOp = function (value) {
    const token = this.peek();
    return token !== undefined && token.type === "op" && token.value === value;
};

// expression := term (("+" | "-") term)*   with "a + b%" meaning a + a*b/100
Parser.prototype.expression = function () {
    let value = this.term();
    while (this.isOp("+") || this.isOp("-")) {
        const op = this.next().value;
        const right = this.term(true);
        // "a + b%" adds b percent of a; right.value is already b / 100.
        const amount = right.percent ? value * right.value : right.value;
        value = op === "+" ? value + amount : value - amount;
    }
    return value;
};

// term := factor (("*" | "/" | implicit) factor)*
Parser.prototype.term = function (allowPercent) {
    let result = this.factor();
    for (;;) {
        if (this.isOp("*") || this.isOp("/")) {
            const op = this.next().value;
            const right = this.factor();
            result = { value: op === "*" ? result.value * right.value : result.value / right.value,
                       percent: false };
        } else {
            const token = this.peek();
            // Implicit multiplication: 2(3), 2pi, (1+1)(2), 3sqrt(4)
            if (token && (token.type === "word" || (token.type === "op" && token.value === "("))) {
                const right = this.factor();
                result = { value: result.value * right.value, percent: false };
            } else {
                break;
            }
        }
    }
    // Only a lone "b%" right after + or - keeps its percent meaning.
    return allowPercent ? result : result.value;
};

// factor := unary then an optional "%"
Parser.prototype.factor = function () {
    const base = this.unary();
    if (this.isOp("%")) {
        this.next();
        return { value: base / 100, percent: true };
    }
    return { value: base, percent: false };
};

// unary := ("-" | "+") unary | power      (so -3^2 = -(3^2) = -9)
Parser.prototype.unary = function () {
    if (this.isOp("-")) {
        this.next();
        return -this.unary();
    }
    if (this.isOp("+")) {
        this.next();
        return this.unary();
    }
    return this.power();
};

// power := primary ("^" unary)?           (right-associative: 2^3^2 = 2^9; 2^-1 works)
Parser.prototype.power = function () {
    const base = this.primary();
    if (this.isOp("^")) {
        this.next();
        return Math.pow(base, this.unary());
    }
    return base;
};

Parser.prototype.primary = function () {
    const token = this.next();
    if (!token)
        throw new Error("unexpected end");
    if (token.type === "num")
        return token.value;
    if (token.type === "op" && token.value === "(") {
        const value = this.expression();
        if (this.isOp(")"))
            this.next(); // a missing ")" at the end is forgiven while typing
        else if (this.peek() !== undefined)
            throw new Error("expected )");
        return value;
    }
    if (token.type === "word") {
        if (CONSTANTS[token.value] !== undefined)
            return CONSTANTS[token.value];
        const fn = FUNCTIONS[token.value];
        if (fn) {
            // sqrt(16)^2 squares the result; "log 1000" (no parentheses) also works.
            const argument = this.isOp("(") ? this.primary() : this.unary();
            return fn(argument);
        }
    }
    throw new Error("unexpected token");
};

// Returns the result as a number, or null when the text is not a complete
// math expression. Plain numbers ("42") are not treated as calculations.
function evaluate(text) {
    const source = String(text || "").trim().replace(/^=\s*/, "");
    if (source === "" || !/[+\-*/%^×÷()]|[a-zA-Zπ]/.test(source.replace(/^[+-]/, "")))
        return null;
    const tokens = tokenize(source);
    if (!tokens || tokens.length === 0)
        return null;
    // Words must be known functions/constants (so app names never parse as math).
    if (tokens.some(token => token.type === "word"
                    && FUNCTIONS[token.value] === undefined && CONSTANTS[token.value] === undefined))
        return null;
    try {
        const parser = new Parser(tokens);
        const value = parser.expression();
        if (parser.pos !== tokens.length || !Number.isFinite(value))
            return null;
        return value;
    } catch (error) {
        return null;
    }
}

// 12 significant digits, no trailing zeros, no exponent for ordinary sizes.
function format(value) {
    if (Number.isInteger(value) && Math.abs(value) < 1e15)
        return String(value);
    const rounded = Number(value.toPrecision(12));
    if (Math.abs(rounded) >= 1e15 || (rounded !== 0 && Math.abs(rounded) < 1e-6))
        return rounded.toExponential(6).replace(/\.?0+e/, "e");
    return String(rounded);
}
