import { useEffect, useState } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { getAllProfiles, updateProfile, getProfile } from "@/db/api";
import type { Profile, UserRole } from "@/types/types";
import { Users, Shield } from "lucide-react";
import { format } from "date-fns";
import { zhCN } from "date-fns/locale";

export default function Admin() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentUserRole, setCurrentUserRole] = useState<UserRole>("user");

  useEffect(() => {
    checkAdminAccess();
  }, [user]);

  const checkAdminAccess = async () => {
    if (!user?.id) {
      navigate("/");
      return;
    }

    try {
      const profile = await getProfile(user.id);
      if (!profile || profile.role !== "admin") {
        toast.error("您没有权限访问此页面");
        navigate("/");
        return;
      }
      setCurrentUserRole(profile.role);
      loadProfiles();
    } catch (error) {
      console.error("检查权限失败:", error);
      navigate("/");
    }
  };

  const loadProfiles = async () => {
    try {
      setLoading(true);
      const data = await getAllProfiles();
      setProfiles(data);
    } catch (error) {
      toast.error("加载用户列表失败");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleRoleChange = async (userId: string, newRole: UserRole) => {
    try {
      await updateProfile(userId, { role: newRole });
      toast.success("角色更新成功");
      loadProfiles();
    } catch (error) {
      toast.error("更新失败");
      console.error(error);
    }
  };

  if (currentUserRole !== "admin") {
    return null;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-purple-50/20 dark:from-gray-950 dark:via-blue-950/20 dark:to-purple-950/10">
      <div className="container mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-6 max-w-7xl">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-xl bg-gradient-to-br from-blue-500/10 to-purple-500/10">
            <Shield className="h-6 w-6 sm:h-8 sm:w-8 text-blue-600 dark:text-blue-400" />
          </div>
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
              管理员面板
            </h1>
            <p className="text-sm sm:text-base text-muted-foreground mt-1">
              管理系统用户和权限
            </p>
          </div>
        </div>

        <Card className="border-0 shadow-lg bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2 text-lg sm:text-xl">
              <Users className="h-5 w-5" />
              <span>用户管理</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="space-y-2">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="h-12 bg-muted animate-pulse rounded" />
                ))}
              </div>
            ) : profiles.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                暂无用户
              </div>
            ) : (
              <div className="overflow-x-auto -mx-4 sm:mx-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="min-w-[100px]">用户ID</TableHead>
                      <TableHead className="min-w-[120px]">手机号</TableHead>
                      <TableHead className="min-w-[150px] hidden sm:table-cell">邮箱</TableHead>
                      <TableHead className="min-w-[80px]">角色</TableHead>
                      <TableHead className="min-w-[150px] hidden md:table-cell">注册时间</TableHead>
                      <TableHead className="min-w-[120px]">操作</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {profiles.map((profile) => (
                      <TableRow key={profile.id}>
                        <TableCell className="font-mono text-xs">
                          {profile.id.substring(0, 8)}...
                        </TableCell>
                        <TableCell className="text-sm">{profile.phone || "-"}</TableCell>
                        <TableCell className="text-sm hidden sm:table-cell">{profile.email || "-"}</TableCell>
                        <TableCell>
                          <Badge
                            variant={
                              profile.role === "admin" ? "default" : "secondary"
                            }
                          >
                            {profile.role === "admin" ? "管理员" : "用户"}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm hidden md:table-cell">
                          {format(
                            new Date(profile.created_at),
                            "yyyy-MM-dd HH:mm",
                            { locale: zhCN }
                          )}
                        </TableCell>
                        <TableCell>
                          <Select
                            value={profile.role}
                            onValueChange={(value: UserRole) =>
                              handleRoleChange(profile.id, value)
                            }
                            disabled={profile.id === user?.id}
                          >
                            <SelectTrigger className="w-28 sm:w-32 text-sm">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="user">用户</SelectItem>
                              <SelectItem value="admin">管理员</SelectItem>
                            </SelectContent>
                          </Select>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
