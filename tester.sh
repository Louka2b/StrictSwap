#!/bin/bash

[ -n "$BASH_VERSION" ] || exec bash "$0" "$@"

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

LANG_FR=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -fr|--fr) LANG_FR=true ;;
        -h|--help) 
            echo "Usage: ./tester.sh [-fr]"
            echo "  -fr, --fr       : Mettre le testeur en Français"
            exit 0
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ "$LANG_FR" = true ]; then
    L_BANNER="STRICTSWAP - TESTEUR PUSH_SWAP (PRO & MÉMOIRE)"
    L_BASE_CHECKS="▶ VÉRIFICATIONS DU DÉPÔT ET DE LA NORME"
    L_NORM="Norminette"
    L_README="Fichier README.md"
    L_COMPILE="Compilation initiale (make)"
    L_RELINK="Test de Relink (make)"
    L_CHECKER="Checker de validation"
    L_ERR_TESTS="▶ TESTS D'ERREURS & LEAKS (Sortie + Valgrind)"
    L_PERF_TESTS="▶ PERFORMANCES"
    L_AVG_MOVES="Moyenne des coups"
    L_WORST_CASE="▶ PIRE CAS ABSOLU (Liste de %d triée à l'envers)"
    L_VALG_TESTS="▶ TESTS VALGRIND : FUITES"
    L_SUMMARY="RÉCAPITULATIF DES CATÉGORIES"
    L_PROMPT="⚠️  DES ERREURS ONT ÉTÉ DÉTECTÉES ! Voir les traces ? [y/N] : "
    L_IGNORE="Traces ignorées."
    L_TRACE_TITLE="TRACE DES ERREURS"
    L_SUCCESS="✅ TOUT EST PARFAIT ! AUCUN KO, AUCUN LEAK."
    L_SUCCESS_SUB="Félicitations, ton projet est prêt pour l'évaluation !"
    L_NOT_TESTED="[IGNORÉ]"
    L_NOT_FOUND="[NON TROUVÉ]"
    
    T_DUP="Doublon classique"
    T_DUP_Z="Doublon vicieux (0 et -0)"
    T_SIGN_OPP="Signes opposés (-42 et +42)"
    T_SIGN_POS="Signe positif interdit (+42)"
    T_SIGN_DBL="Signe doublé (++42)"
    T_SIGN_INV="Signe inversé (-+42)"
    T_SIGN_END="Signe à la fin (42-)"
    T_MAX="Dépassement INT_MAX"
    T_MIN="Dépassement INT_MIN"
    T_EMPTY="Argument vide"
else
    L_BANNER="STRICTSWAP - PUSH_SWAP TESTER (PRO & MEMORY)"
    L_BASE_CHECKS="▶ REPOSITORY & NORM CHECKS"
    L_NORM="Norminette"
    L_README="README.md File"
    L_COMPILE="Initial Compilation (make)"
    L_RELINK="Relink Test (make)"
    L_CHECKER="Validation Checker"
    L_ERR_TESTS="▶ ERROR & LEAK TESTS (Output + Valgrind)"
    L_PERF_TESTS="▶ PERFORMANCES"
    L_AVG_MOVES="Average moves"
    L_WORST_CASE="▶ ABSOLUTE WORST CASE (Reverse sorted list of %d)"
    L_VALG_TESTS="▶ VALGRIND TESTS: LEAKS"
    L_SUMMARY="CATEGORY SUMMARY"
    L_PROMPT="⚠️  ERRORS DETECTED! Do you want to show trace details? [y/N] : "
    L_IGNORE="Traces ignored."
    L_TRACE_TITLE="ERROR TRACE"
    L_SUCCESS="✅ EVERYTHING IS PERFECT! NO KO, NO LEAKS."
    L_SUCCESS_SUB="Congratulations, your project is ready for evaluation!"
    L_NOT_TESTED="[SKIPPED]"
    L_NOT_FOUND="[NOT FOUND]"
    
    T_DUP="Classic duplicate"
    T_DUP_Z="Vicious duplicate (0 and -0)"
    T_SIGN_OPP="Opposite signs (-42 and +42)"
    T_SIGN_POS="Forbidden positive sign (+42)"
    T_SIGN_DBL="Double sign (++42)"
    T_SIGN_INV="Inverted sign (-+42)"
    T_SIGN_END="Sign at the end (42-)"
    T_MAX="INT_MAX Overflow"
    T_MIN="INT_MIN Underflow"
    T_EMPTY="Empty argument"
fi

PUSH_SWAP="./push_swap"
ERROR_REPORT=""

C_GREEN=$(printf '\033[1;32m')
C_RED=$(printf '\033[1;31m')
C_YELLOW=$(printf '\033[1;33m')
C_BLUE=$(printf '\033[1;34m')
C_CYAN=$(printf '\033[1;36m')
C_MAGENTA=$(printf '\033[1;35m')
C_BOLD=$(printf '\033[1m')
C_RESET=$(printf '\033[0m')

RES_NORM="${C_GREEN}[OK]${C_RESET}"
RES_README="${C_GREEN}[OK]${C_RESET}"
RES_MAKEFILE="${C_GREEN}[OK]${C_RESET}"
RES_SUBTLE="${C_GREEN}[OK]${C_RESET}"
RES_PERF_3="${C_GREEN}[OK]${C_RESET}"
RES_PERF_5="${C_GREEN}[OK]${C_RESET}"
RES_PERF_100="${C_GREEN}[OK]${C_RESET}"
RES_PERF_500="${C_GREEN}[OK]${C_RESET}"
RES_WORST="${C_GREEN}[OK]${C_RESET}"
RES_VALGRIND="${C_GREEN}[OK]${C_RESET}"
GRADE_100="${C_CYAN}N/A${C_RESET}"
GRADE_500="${C_CYAN}N/A${C_RESET}"

clear
echo "${C_BLUE}${C_BOLD}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
printf "${C_BLUE}${C_BOLD}║ %-60s ║${C_RESET}\n" "$(printf "%*s" $(((60+${#L_BANNER})/2)) "$L_BANNER")"
echo "${C_BLUE}${C_BOLD}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
echo ""

generate_args() {
    seq -10000 10000 | shuf -n $1 | tr '\n' ' '
}

add_error() {
    local type=$1
    local size=$2
    local reason=$3
    local cmd=$4
    ERROR_REPORT="${ERROR_REPORT}${C_RED}[KO - ${type}]${C_RESET} ${C_YELLOW}${size}${C_RESET} | Raison: ${C_BOLD}${reason}${C_RESET}\n  ↳ CMD: ${C_CYAN}${cmd}${C_RESET}\n\n"
}

get_grade_info() {
    local size=$1
    local ops=$2
    local score=0
    local max=0

    if [ "$size" -le 3 ]; then max=3; if [ "$ops" -le 3 ]; then score=5; else score=0; fi
    elif [ "$size" -le 5 ]; then max=12; if [ "$ops" -le 12 ]; then score=5; else score=0; fi
    elif [ "$size" -eq 100 ]; then max=1500
        if [ "$ops" -lt 700 ]; then score=5; elif [ "$ops" -lt 900 ]; then score=4; elif [ "$ops" -lt 1100 ]; then score=3; elif [ "$ops" -lt 1300 ]; then score=2; elif [ "$ops" -lt 1500 ]; then score=1; else score=0; fi
    elif [ "$size" -eq 500 ]; then max=11500
        if [ "$ops" -lt 5500 ]; then score=5; elif [ "$ops" -lt 7000 ]; then score=4; elif [ "$ops" -lt 8500 ]; then score=3; elif [ "$ops" -lt 10000 ]; then score=2; elif [ "$ops" -lt 11500 ]; then score=1; else score=0; fi
    else max="-"; score=5; fi

    echo "$score|$max"
}

set_perf_ko() {
    if [ "$1" -eq 3 ]; then RES_PERF_3="${C_RED}[KO]${C_RESET}"; fi
    if [ "$1" -eq 5 ]; then RES_PERF_5="${C_RED}[KO]${C_RESET}"; fi
    if [ "$1" -eq 100 ]; then RES_PERF_100="${C_RED}[KO]${C_RESET}"; fi
    if [ "$1" -eq 500 ]; then RES_PERF_500="${C_RED}[KO]${C_RESET}"; fi
}

echo "${C_CYAN}${C_BOLD}${L_BASE_CHECKS}${C_RESET}"

printf "  %-32s : " "$L_NORM"
if command -v norminette >/dev/null 2>&1; then
    NORM_ERR=$(norminette 2>&1 | grep -E "Error|Warning")
    if [ -z "$NORM_ERR" ]; then
        echo "${C_GREEN}[OK]${C_RESET}"
    else
        echo "${C_RED}[KO]${C_RESET}"
        add_error "NORME" "Fichiers" "Erreurs de norme" "norminette"
        RES_NORM="${C_RED}[KO]${C_RESET}"
    fi
else
    echo "${C_YELLOW}${L_NOT_TESTED}${C_RESET}"
    RES_NORM="${C_CYAN}${L_NOT_TESTED}${C_RESET}"
fi

printf "  %-32s : " "$L_README"
if [ -f "README.md" ]; then
    FIRST_LINE=$(head -n 1 README.md | tr -d '\r')
    if echo "$FIRST_LINE" | grep -qiE "^[\*\_]?This project has been created as part of the 42 curriculum by"; then
        echo "${C_GREEN}[OK]${C_RESET}"
    else
        echo "${C_RED}[KO]${C_RESET}"
        add_error "README" "Fichier" "Mauvaise première ligne" "cat README.md"
        RES_README="${C_RED}[KO]${C_RESET}"
    fi
else
    echo "${C_RED}[KO]${C_RESET}"
    add_error "README" "Fichier" "Le fichier README.md n'existe pas" "ls -la"
    RES_README="${C_RED}[KO]${C_RESET}"
fi

printf "  %-32s : " "$L_COMPILE"
make > /dev/null 2>&1
if [ ! -f "$PUSH_SWAP" ]; then
    echo "${C_RED}[KO]${C_RESET}"
    exit 1
fi
echo "${C_GREEN}[OK]${C_RESET}"

printf "  %-32s : " "$L_RELINK"
MAKE_OUT=$(make 2>&1)
if echo "$MAKE_OUT" | grep -qiE "nothing to be done|up to date|up-to-date"; then
    echo "${C_GREEN}[OK]${C_RESET}"
else
    echo "${C_RED}[KO]${C_RESET}"
    add_error "MAKEFILE" "Relink" "Le programme a été recompilé" "make && make"
    RES_MAKEFILE="${C_RED}[KO]${C_RESET}"
fi

if [ -f "./checker_linux" ] && [ ! -x "./checker_linux" ]; then
    echo "checker_linux exists but is not executable."
    read -p "Make it executable? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        chmod +x checker_linux 2>/dev/null || echo "chmod failed" >&2
    fi
fi

if [ -f "./checker_linux" ]; then
    CHECKER_CMD="./checker_linux"
elif [ -f "./checker_Mac" ]; then
    CHECKER_CMD="./checker_Mac"
elif [ -f "./checker" ]; then
    CHECKER_CMD="./checker"
else
    CHECKER_CMD="wc -c > /dev/null"
fi

printf "  %-32s : " "$L_CHECKER"
if [ "$CHECKER_CMD" = "wc -c > /dev/null" ]; then
    echo "${C_YELLOW}${L_NOT_FOUND}${C_RESET}"
else
    chmod +x "$CHECKER_CMD" 2>/dev/null
    echo "${C_GREEN}[OK]${C_RESET} ($CHECKER_CMD)"
fi
echo ""

echo "${C_CYAN}${C_BOLD}${L_ERR_TESTS}${C_RESET}"

test_error_case() {
    local msg=$1
    local args=$2
    local expected=$3 
    
    local output=$(eval "$PUSH_SWAP $args 2>&1")
    local lines=$(echo "$output" | wc -l | tr -d ' ')
    
    local out_status="${C_GREEN}[OK]${C_RESET}"
    if [ "$expected" = "Error" ]; then
        if ! echo "$output" | grep -q "Error"; then
            out_status="${C_RED}[KO]${C_RESET}"
            add_error "PARSING" "$msg" "Ne renvoie pas 'Error'" "./push_swap $args"
            RES_SUBTLE="${C_RED}[KO]${C_RESET}"
        fi
    elif [ "$expected" = "None" ]; then
        if [ -n "$output" ] && [ "$lines" -gt 0 ]; then
            out_status="${C_RED}[KO]${C_RESET}"
            add_error "PARSING" "$msg" "Affiche un résultat au lieu de s'arrêter proprement" "./push_swap $args"
            RES_SUBTLE="${C_RED}[KO]${C_RESET}"
        fi
    elif [ "$expected" = "Sort" ]; then
        if [ "$CHECKER_CMD" != "wc -c > /dev/null" ]; then
            local chk=$(echo "$output" | eval "$CHECKER_CMD $args 2>/dev/null")
            if [ "$chk" != "OK" ]; then
                out_status="${C_RED}[KO]${C_RESET}"
                add_error "TRI" "$msg" "Le programme a crashé ou mal trié" "./push_swap $args"
                RES_SUBTLE="${C_RED}[KO]${C_RESET}"
            fi
        fi
    fi

    local valg_status="${C_CYAN}[N/A]${C_RESET}"
    if command -v valgrind >/dev/null 2>&1; then
        local valg_out=$(eval "valgrind --leak-check=full --errors-for-leak-kinds=all --error-exitcode=1 $PUSH_SWAP $args 2>&1 >/dev/null")
        if echo "$valg_out" | grep -qE "definitely lost: [1-9]|indirectly lost: [1-9]|possibly lost: [1-9]|still reachable: [1-9]|errors: [1-9]"; then
            valg_status="${C_RED}[KO]${C_RESET}"
            add_error "VALGRIND" "$msg" "Leak détecté lors de l'arrêt du programme" "valgrind ./push_swap $args"
            RES_SUBTLE="${C_RED}[KO]${C_RESET}"
        else
            valg_status="${C_GREEN}[OK]${C_RESET}"
        fi
    fi

    printf "  %-32s | Output: %b | Valgrind: %b\n" "$msg" "$out_status" "$valg_status"
}

test_error_case "$T_DUP" "1 2 2 3" "Error"
test_error_case "$T_DUP_Z" "0 00" "Error"
test_error_case "$T_SIGN_OPP" "-42 +42" "Error"
test_error_case "$T_SIGN_POS" "+42" "Error"
test_error_case "$T_SIGN_DBL" "++42" "Error"
test_error_case "$T_SIGN_INV" "-+42" "Error"
test_error_case "$T_SIGN_END" "42-" "Error"
test_error_case "$T_MAX" "2147483648" "Error"
test_error_case "$T_MIN" "-2147483649" "Error"
test_error_case "$T_EMPTY" '""' "None"
echo ""

test_performance() {
    local SIZE=$1
    local ITERATIONS=$2
    local SUM_LINES=0
    
    echo "${C_CYAN}${C_BOLD}${L_PERF_TESTS} ($SIZE | $ITERATIONS ops)${C_RESET}"
    
    i=1
    while [ "$i" -le "$ITERATIONS" ]; do
        ARG=$(generate_args "$SIZE")
        
        N=$(./push_swap $ARG | wc -l | tr -d ' ')
        if [ -z "$N" ]; then N=0; fi

        S="OK"
        if [ "$CHECKER_CMD" != "wc -c > /dev/null" ]; then
            S=$(./push_swap $ARG | $CHECKER_CMD $ARG 2>/dev/null)
        fi

        GRADE_DATA=$(get_grade_info "$SIZE" "$N")
        SCORE=$(echo "$GRADE_DATA" | cut -d'|' -f1)
        MAX_ALLOWED=$(echo "$GRADE_DATA" | cut -d'|' -f2)

        REASON=""
        SORT_STATUS="${C_GREEN}[OK]${C_RESET}"
        
        if [ "$S" != "OK" ] && [ "$N" -gt 0 ]; then
            SORT_STATUS="${C_RED}[KO]${C_RESET}"
            REASON="Tri incorrect"
        fi

        if [ "$SCORE" -eq 0 ] && [ "$MAX_ALLOWED" != "-" ]; then
            if [ -n "$REASON" ]; then REASON="$REASON + "; fi
            REASON="${REASON}Coups max dépassés"
        fi

        if [ "$MAX_ALLOWED" = "-" ]; then
            RAW_OPS="$N"
            OPS_COLOR="$C_CYAN"
        else
            if [ "$SCORE" -eq 0 ]; then OPS_COLOR="$C_RED"; else OPS_COLOR="$C_GREEN"; fi
            RAW_OPS="$N/$MAX_ALLOWED"
        fi

        PAD_OPS=$(printf "%-9s" "$RAW_OPS")
        PRINT_OPS="${OPS_COLOR}${PAD_OPS}${C_RESET}"

        if [ "$SCORE" -lt 3 ]; then GRADE_STR="${C_RED}[${SCORE}/5]${C_RESET}"
        elif [ "$SCORE" -lt 5 ]; then GRADE_STR="${C_YELLOW}[${SCORE}/5]${C_RESET}"
        else GRADE_STR="${C_GREEN}[${SCORE}/5]${C_RESET}"; fi

        if [ -n "$REASON" ]; then
            printf "  Test [%02d/%02d] | Sort: %b | Ops: %b | Grade: %b ${C_RED}<- KO (%s)${C_RESET}\n" "$i" "$ITERATIONS" "$SORT_STATUS" "$PRINT_OPS" "$GRADE_STR" "$REASON"
            add_error "PERF/TRI" "Size $SIZE" "$REASON" "./push_swap $ARG"
            set_perf_ko "$SIZE"
        else
            printf "  Test [%02d/%02d] | Sort: %b | Ops: %b | Grade: %b\n" "$i" "$ITERATIONS" "$SORT_STATUS" "$PRINT_OPS" "$GRADE_STR"
        fi

        SUM_LINES=$((SUM_LINES + N))
        i=$((i + 1))
    done

    AVG_LINES=$((SUM_LINES / ITERATIONS))
    echo "  -> ${L_AVG_MOVES} : $AVG_LINES"
    echo ""

    if [ "$SIZE" -eq 100 ]; then
        GRADE_DATA=$(get_grade_info 100 $AVG_LINES)
        SCORE=$(echo "$GRADE_DATA" | cut -d'|' -f1)
        if [ "$SCORE" -lt 3 ]; then GRADE_100="${C_RED}[${SCORE}/5]${C_RESET}"
        elif [ "$SCORE" -lt 5 ]; then GRADE_100="${C_YELLOW}[${SCORE}/5]${C_RESET}"
        else GRADE_100="${C_GREEN}[${SCORE}/5]${C_RESET}"; fi
    elif [ "$SIZE" -eq 500 ]; then
        GRADE_DATA=$(get_grade_info 500 $AVG_LINES)
        SCORE=$(echo "$GRADE_DATA" | cut -d'|' -f1)
        if [ "$SCORE" -lt 3 ]; then GRADE_500="${C_RED}[${SCORE}/5]${C_RESET}"
        elif [ "$SCORE" -lt 5 ]; then GRADE_500="${C_YELLOW}[${SCORE}/5]${C_RESET}"
        else GRADE_500="${C_GREEN}[${SCORE}/5]${C_RESET}"; fi
    fi
}

test_worst_case() {
    local SIZE=$1
    local STR_WORST=$(printf "$L_WORST_CASE" "$SIZE")
    echo "${C_CYAN}${C_BOLD}${STR_WORST}${C_RESET}"
    
    ARG=$(seq $SIZE -1 1 | tr '\n' ' ')
    N=$(./push_swap $ARG | wc -l | tr -d ' ')
    if [ -z "$N" ]; then N=0; fi

    S="OK"
    if [ "$CHECKER_CMD" != "wc -c > /dev/null" ]; then
        S=$(./push_swap $ARG | $CHECKER_CMD $ARG 2>/dev/null)
    fi

    GRADE_DATA=$(get_grade_info "$SIZE" "$N")
    SCORE=$(echo "$GRADE_DATA" | cut -d'|' -f1)
    MAX_ALLOWED=$(echo "$GRADE_DATA" | cut -d'|' -f2)

    REASON=""
    SORT_STATUS="${C_GREEN}[OK]${C_RESET}"
    
    if [ "$S" != "OK" ] && [ "$N" -gt 0 ]; then
        SORT_STATUS="${C_RED}[KO]${C_RESET}"
        REASON="Tri incorrect"
    fi

    if [ "$SCORE" -eq 0 ] && [ "$MAX_ALLOWED" != "-" ]; then
        if [ -n "$REASON" ]; then REASON="$REASON + "; fi
        REASON="${REASON}Coups max dépassés"
    fi

    if [ "$MAX_ALLOWED" = "-" ]; then
        RAW_OPS="$N"
        OPS_COLOR="$C_CYAN"
    else
        if [ "$SCORE" -eq 0 ]; then OPS_COLOR="$C_RED"; else OPS_COLOR="$C_GREEN"; fi
        RAW_OPS="$N/$MAX_ALLOWED"
    fi

    PAD_OPS=$(printf "%-9s" "$RAW_OPS")
    PRINT_OPS="${OPS_COLOR}${PAD_OPS}${C_RESET}"

    if [ "$SCORE" -lt 3 ]; then GRADE_STR="${C_RED}[${SCORE}/5]${C_RESET}"
    elif [ "$SCORE" -lt 5 ]; then GRADE_STR="${C_YELLOW}[${SCORE}/5]${C_RESET}"
    else GRADE_STR="${C_GREEN}[${SCORE}/5]${C_RESET}"; fi

    if [ -n "$REASON" ]; then
        printf "  Test [Unique] | Sort: %b | Ops: %b | Grade: %b ${C_RED}<- KO (%s)${C_RESET}\n" "$SORT_STATUS" "$PRINT_OPS" "$GRADE_STR" "$REASON"
        add_error "PERF/TRI" "Pire Cas $SIZE" "$REASON" "./push_swap \$(seq $SIZE -1 1)"
        RES_WORST="${C_RED}[KO]${C_RESET}"
    else
        printf "  Test [Unique] | Sort: %b | Ops: %b | Grade: %b\n" "$SORT_STATUS" "$PRINT_OPS" "$GRADE_STR"
    fi
    echo ""
}

test_valgrind() {
    local SIZE=$1
    local ITERATIONS=$2
    local CMD_PREFIX="valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=1"

    echo "${C_MAGENTA}${C_BOLD}${L_VALG_TESTS} ($SIZE | $ITERATIONS ops)${C_RESET}"
    
    i=1
    while [ "$i" -le "$ITERATIONS" ]; do
        ARG=$(generate_args "$SIZE")
        
        local valg_out=$(eval "$CMD_PREFIX ./push_swap $ARG 2>&1 >/dev/null")

        LEAK_STATUS="${C_GREEN}[OK]${C_RESET}"
        if echo "$valg_out" | grep -qE "definitely lost: [1-9]|indirectly lost: [1-9]|possibly lost: [1-9]|still reachable: [1-9]|errors: [1-9]"; then
            LEAK_STATUS="${C_RED}[KO]${C_RESET}"
            printf "  Test [%02d/%02d] | Valgrind: %b ${C_RED}<- KO (Fuite de mémoire)${C_RESET}\n" "$i" "$ITERATIONS" "$LEAK_STATUS"
            add_error "VALGRIND" "Size $SIZE" "Fuite de mémoire Valgrind" "valgrind ./push_swap $ARG"
            RES_VALGRIND="${C_RED}[KO]${C_RESET}"
        else
            printf "  Test [%02d/%02d] | Valgrind: %b\n" "$i" "$ITERATIONS" "$LEAK_STATUS"
        fi
        i=$((i + 1))
    done
    echo ""
}

ITER_PERF=30
ITER_MEM=5

test_performance 3 $ITER_PERF
test_performance 5 $ITER_PERF
test_performance 100 $ITER_PERF
test_performance 500 $ITER_PERF

test_worst_case 3
test_worst_case 5
test_worst_case 500

if command -v valgrind >/dev/null 2>&1; then
    test_valgrind 3 $ITER_MEM
    test_valgrind 5 $ITER_MEM
    test_valgrind 100 $ITER_MEM
    test_valgrind 500 $ITER_MEM
else
    RES_VALGRIND="${C_CYAN}${L_NOT_TESTED}${C_RESET}"
fi

echo "${C_BLUE}${C_BOLD}══════════════════════════════════════════════════════════════${C_RESET}"
printf "${C_BLUE}${C_BOLD}║ %-60s ║${C_RESET}\n" "$(printf "%*s" $(((60+${#L_SUMMARY})/2)) "$L_SUMMARY")"
echo "${C_BLUE}${C_BOLD}══════════════════════════════════════════════════════════════${C_RESET}"

if [ "$LANG_FR" = true ]; then
    printf " %-32s : %b\n" "Norminette" "$RES_NORM"
    printf " %-32s : %b\n" "Fichier README.md" "$RES_README"
    printf " %-32s : %b\n" "Makefile (Relink)" "$RES_MAKEFILE"
    printf " %-32s : %b\n" "Erreurs & Cas Subtils" "$RES_SUBTLE"
    printf " %-32s : %b\n" "Performances (3 Nums)" "$RES_PERF_3"
    printf " %-32s : %b\n" "Performances (5 Nums)" "$RES_PERF_5"
    printf " %-32s : %b (Note : %b)\n" "Performances (100 Nums)" "$RES_PERF_100" "$GRADE_100"
    printf " %-32s : %b (Note : %b)\n" "Performances (500 Nums)" "$RES_PERF_500" "$GRADE_500"
    printf " %-32s : %b\n" "Pires Cas (3, 5, 500 Reverse)" "$RES_WORST"
    printf " %-32s : %b\n" "Outil Valgrind (Leaks)" "$RES_VALGRIND"
else
    printf " %-32s : %b\n" "Norminette" "$RES_NORM"
    printf " %-32s : %b\n" "README.md File" "$RES_README"
    printf " %-32s : %b\n" "Makefile (Relink)" "$RES_MAKEFILE"
    printf " %-32s : %b\n" "Errors & Subtle Cases" "$RES_SUBTLE"
    printf " %-32s : %b\n" "Performances (3 Nums)" "$RES_PERF_3"
    printf " %-32s : %b\n" "Performances (5 Nums)" "$RES_PERF_5"
    printf " %-32s : %b (Grade: %b)\n" "Performances (100 Nums)" "$RES_PERF_100" "$GRADE_100"
    printf " %-32s : %b (Grade: %b)\n" "Performances (500 Nums)" "$RES_PERF_500" "$GRADE_500"
    printf " %-32s : %b\n" "Worst Cases (3, 5, 500 Rev)" "$RES_WORST"
    printf " %-32s : %b\n" "Valgrind Tool (Leaks)" "$RES_VALGRIND"
fi

echo ""

if [ -n "$ERROR_REPORT" ]; then
    echo "${C_RED}${C_BOLD}${L_PROMPT}${C_RESET}"
    read -r response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY]|o|O|oui|Oui)$ ]]; then
        echo ""
        echo "${C_RED}${C_BOLD}====================== ${L_TRACE_TITLE} =====================${C_RESET}"
        echo -e "$ERROR_REPORT"
        echo "${C_RED}${C_BOLD}==============================================================${C_RESET}"
    else
        echo "$L_IGNORE"
    fi
else
    echo "${C_GREEN}${C_BOLD}${L_SUCCESS}${C_RESET}"
    echo "$L_SUCCESS_SUB"
fi
echo "${C_BLUE}${C_BOLD}══════════════════════════════════════════════════════════════${C_RESET}"