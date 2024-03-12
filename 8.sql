CREATE OR REPLACE FUNCTION actualizare_buget
    (p_id_proiect PROIECT.ID_PROIECT%TYPE)
 RETURN SPONSORI.SUMA%TYPE IS
    buget SPONSORI.SUMA%TYPE;
    v_titlu_proiect PROIECT.TITLU_PROIECT%TYPE;
    v_nume_club CLUBURI.NUME_CLUB%TYPE;
    
    PROIECT_INTERN EXCEPTION;
    BUGET_INSUFICIENT EXCEPTION;
 BEGIN
    SELECT 
        SUM(S.SUMA) - 1500, P.TITLU_PROIECT, C.NUME_CLUB
        INTO buget, v_titlu_proiect, v_nume_club
        FROM SPONSORI S
        JOIN PROIECT P
        ON(S.ID_PROIECT = P.ID_PROIECT)
        JOIN CLUBURI C
        ON(P.ID_CLUB = C.ID_CLUB)
        WHERE S.ID_PROIECT = p_id_proiect
        GROUP BY P.TITLU_PROIECT, C.NUME_CLUB;
    
    IF buget + 1500 <= 300 THEN
        RAISE PROIECT_INTERN;
    END IF;

    IF buget < 0 THEN
        RAISE BUGET_INSUFICIENT;   
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Proiectul ' || v_titlu_proiect || ' din clubul ' || v_nume_club || ' va ramane cu un buget de ');
    RETURN buget;
    
 EXCEPTION
    WHEN NO_DATA_FOUND OR PROIECT_INTERN THEN
        RAISE_APPLICATION_ERROR(-20004, 'Proiectul este intern si nu are nevoie de materiale!');     
        
    WHEN BUGET_INSUFICIENT THEN
        RAISE_APPLICATION_ERROR(-20003, 'Bugetul este prea mic pentru realizarea cumparaturilor!');  
        
 END actualizare_buget;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(actualizare_buget(61));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(actualizare_buget(110));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(actualizare_buget(82));
END;
/
