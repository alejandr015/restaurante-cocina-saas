// @ts-ignore - Deno imports work at runtime in Supabase Edge Functions
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ReqBody {
  accion: "crear" | "listar" | "eliminar" | "actualizar_password";
  email?: string;
  password?: string;
  nombre?: string;
  rol?: "admin" | "cocina" | "mesero";
  user_id?: string;
}

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Cliente con service_role (poder total - solo para servidor)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // 2. Cliente con la sesión del usuario que llama (para validar quién es)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "No autorizado" }, 401);
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // 3. Verificar quién está llamando
    const {
      data: { user },
      error: userError,
    } = await supabaseUser.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "No autenticado" }, 401);
    }

    // 4. Verificar que sea admin de algún restaurante
    const { data: vinculo, error: vinculoError } = await supabaseAdmin
      .from("usuarios_restaurante")
      .select("rol, restaurante_id")
      .eq("user_id", user.id)
      .single();

    if (vinculoError || !vinculo) {
      return jsonResponse({ error: "Usuario sin restaurante" }, 403);
    }

    if (vinculo.rol !== "admin") {
      return jsonResponse(
        { error: "Solo los administradores pueden gestionar usuarios" },
        403
      );
    }

    const restauranteId = vinculo.restaurante_id;

    // 5. Procesar la acción solicitada
    const body: ReqBody = await req.json();

    switch (body.accion) {
      case "listar":
        return await listarUsuarios(supabaseAdmin, restauranteId);

      case "crear":
        return await crearUsuario(supabaseAdmin, restauranteId, body);

      case "eliminar":
        return await eliminarUsuario(supabaseAdmin, restauranteId, body);

      case "actualizar_password":
        return await actualizarPassword(supabaseAdmin, restauranteId, body);

      default:
        return jsonResponse({ error: "Acción no válida" }, 400);
    }
  } catch (error) {
    return jsonResponse(
      { error: `Error interno: ${(error as Error).message}` },
      500
    );
  }
});

// ============================================================
// ACCIONES
// ============================================================

async function listarUsuarios(supabaseAdmin: any, restauranteId: string) {
  // Trae los vínculos del restaurante con la info del perfil
  const { data: vinculos, error } = await supabaseAdmin
    .from("usuarios_restaurante")
    .select("user_id, rol, created_at")
    .eq("restaurante_id", restauranteId);

  if (error) return jsonResponse({ error: error.message }, 500);

  // Para cada vínculo, obtener email del usuario
  const usuarios = [];
  for (const v of vinculos ?? []) {
    const { data: userData } =
      await supabaseAdmin.auth.admin.getUserById(v.user_id);
    if (userData?.user) {
      usuarios.push({
        user_id: v.user_id,
        email: userData.user.email,
        rol: v.rol,
        nombre: userData.user.user_metadata?.nombre ?? null,
        creado_en: v.created_at,
      });
    }
  }

  return jsonResponse({ usuarios });
}

async function crearUsuario(
  supabaseAdmin: any,
  restauranteId: string,
  body: ReqBody
) {
  if (!body.email || !body.password || !body.rol) {
    return jsonResponse(
      { error: "Faltan datos: email, password y rol son requeridos" },
      400
    );
  }

  if (!["admin", "cocina", "mesero"].includes(body.rol)) {
    return jsonResponse({ error: "Rol no válido" }, 400);
  }

  if (body.password.length < 6) {
    return jsonResponse(
      { error: "La contraseña debe tener al menos 6 caracteres" },
      400
    );
  }

  // 1. Crear el usuario en Auth
  const { data: nuevo, error: errorCrear } =
    await supabaseAdmin.auth.admin.createUser({
      email: body.email,
      password: body.password,
      email_confirm: true,
      user_metadata: { nombre: body.nombre ?? "" },
    });

  if (errorCrear || !nuevo.user) {
    return jsonResponse(
      { error: errorCrear?.message ?? "Error al crear usuario" },
      400
    );
  }

  // 2. Crear el vínculo con el restaurante
  const { error: errorVinculo } = await supabaseAdmin
    .from("usuarios_restaurante")
    .insert({
      user_id: nuevo.user.id,
      restaurante_id: restauranteId,
      rol: body.rol,
    });

  if (errorVinculo) {
    // Si falla, eliminar el usuario de Auth para no dejar basura
    await supabaseAdmin.auth.admin.deleteUser(nuevo.user.id);
    return jsonResponse({ error: errorVinculo.message }, 500);
  }

  return jsonResponse({
    success: true,
    user_id: nuevo.user.id,
    email: nuevo.user.email,
  });
}

async function eliminarUsuario(
  supabaseAdmin: any,
  restauranteId: string,
  body: ReqBody
) {
  if (!body.user_id) {
    return jsonResponse({ error: "Falta user_id" }, 400);
  }

  // Verificar que el usuario a eliminar pertenece al mismo restaurante
  const { data: vinculo } = await supabaseAdmin
    .from("usuarios_restaurante")
    .select("rol, restaurante_id")
    .eq("user_id", body.user_id)
    .single();

  if (!vinculo || vinculo.restaurante_id !== restauranteId) {
    return jsonResponse(
      { error: "Usuario no encontrado en este restaurante" },
      404
    );
  }

  // Eliminar el vínculo (luego CASCADE elimina el usuario)
  await supabaseAdmin
    .from("usuarios_restaurante")
    .delete()
    .eq("user_id", body.user_id);

  // Eliminar de Auth
  const { error } = await supabaseAdmin.auth.admin.deleteUser(body.user_id);

  if (error) return jsonResponse({ error: error.message }, 500);

  return jsonResponse({ success: true });
}

async function actualizarPassword(
  supabaseAdmin: any,
  restauranteId: string,
  body: ReqBody
) {
  if (!body.user_id || !body.password) {
    return jsonResponse({ error: "Faltan user_id o password" }, 400);
  }

  if (body.password.length < 6) {
    return jsonResponse(
      { error: "La contraseña debe tener al menos 6 caracteres" },
      400
    );
  }

  // Verificar que el usuario pertenece al mismo restaurante
  const { data: vinculo } = await supabaseAdmin
    .from("usuarios_restaurante")
    .select("restaurante_id")
    .eq("user_id", body.user_id)
    .single();

  if (!vinculo || vinculo.restaurante_id !== restauranteId) {
    return jsonResponse(
      { error: "Usuario no encontrado en este restaurante" },
      404
    );
  }

  const { error } = await supabaseAdmin.auth.admin.updateUserById(
    body.user_id,
    { password: body.password }
  );

  if (error) return jsonResponse({ error: error.message }, 500);

  return jsonResponse({ success: true });
}

// ============================================================
// HELPERS
// ============================================================

function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
