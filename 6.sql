CREATE OR REPLACE PROCEDURE atribuire_taskuri
 IS 
        statusul TASK.STATUS%TYPE;

    TYPE TASK_TABLE IS TABLE OF TASK%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE TASK_VARRAY IS VARRAY(100) OF TASK%ROWTYPE;
    TYPE TASK_MEMBRI IS TABLE OF TASK.ID_MEMBRU%TYPE;
    
    contor NUMBER := 1;
    taskuri_realizate TASK_TABLE;
    taskuri_fara_membru TASK_VARRAY := TASK_VARRAY();
    id_membri_asignati TASK_MEMBRI := TASK_MEMBRI();
    
    CURSOR c_taskuri_realizate IS
        SELECT * 
        FROM TASK
        WHERE STATUS = 'Realizat';
    
    CURSOR c_taskuri_fara_membru IS
        SELECT *
        FROM TASK
        WHERE ID_MEMBRU IS NULL;
        
    CURSOR c_taskuri_cu_membru IS
        SELECT DISTINCT ID_MEMBRU
        FROM TASK
        WHERE ID_MEMBRU IS NOT NULL;
        
    CURSOR c_membri_activi IS
        SELECT ID_MEMBRU
        FROM MEMBRI_ACTIVI;
 BEGIN 
    FOR task_rec IN c_taskuri_realizate LOOP
        taskuri_realizate(taskuri_realizate.COUNT + 1) := task_rec;
    END LOOP;
    
    FOR i IN 1..taskuri_realizate.COUNT LOOP
        DELETE 
        FROM TASK
        WHERE ID_TASK = taskuri_realizate(i).ID_TASK;
    END LOOP;
    
    FOR task_rec IN c_taskuri_fara_membru LOOP
        taskuri_fara_membru.EXTEND;
        taskuri_fara_membru(taskuri_fara_membru.LAST) := task_rec;
    END LOOP;
    
    FOR task_rec IN c_taskuri_cu_membru LOOP
        id_membri_asignati.EXTEND;
        id_membri_asignati(id_membri_asignati.LAST) := task_rec.ID_MEMBRU;
    END LOOP;
    
    FOR membru_rec IN c_membri_activi LOOP
        IF contor <= taskuri_fara_membru.COUNT THEN 
            UPDATE TASK
            SET ID_MEMBRU = membru_rec.ID_MEMBRU
            WHERE ID_TASK = taskuri_fara_membru(contor).ID_TASK;
            contor := contor + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
 END atribuire_taskuri;
/


BEGIN
    atribuire_taskuri;
END;
/

COMMIT;